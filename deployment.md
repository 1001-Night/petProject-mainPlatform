# Развёртывание mainPlatform в Yandex Cloud

Подробный runbook для разворачивания платформы с нуля: от Terraform bootstrap до работающего Kubernetes-кластера с Argo CD, TLS и мониторингом.

## Что нужно для облачного стенда

- аккаунт и каталог в Yandex Cloud;
- домен, делегированный в Yandex Cloud DNS;
- `yc`;
- Terraform 1.10 или новее;
- Ansible;
- Git;
- SSH-клиент;
- Tailscale;
- GitHub CLI для настройки Actions;
- Linux или WSL для запуска Ansible.

Также нужны два SSH-ключа:

- административный ключ для ручной настройки;
- deploy-ключ для автоматизации.

Секреты, `terraform.tfvars`, inventory, kubeconfig и Terraform state не должны попадать в Git.

## Перед запуском в своей копии нужно заменить

- домены в `infra/terraform/dns.tf` и Helm values;
- `repoURL` в Argo CD Application;
- имя S3 bucket в Terraform helper-скриптах;
- GitHub owner и repository в bootstrap variables.

## 1. Авторизация в Yandex Cloud

```bash
yc init
yc config list
```

Нужно сохранить `cloud-id` и `folder-id`: они используются в Terraform.

## 2. Bootstrap для Terraform state

Bootstrap создаёт постоянный слой:

- Object Storage bucket;
- KMS-ключ;
- сервисные аккаунты;
- Lockbox secrets;
- Workload Identity Federation для GitHub Actions.

```bash
cd infra/terraform-bootstrap
cp terraform.tfvars.example terraform.tfvars
```

В `terraform.tfvars` необходимо указать свои `cloud_id`, `folder_id` и уникальное имя bucket.

При самом первом развёртывании bucket ещё не существует, поэтому bootstrap сначала запускается с локальным state. Для этого нужно временно убрать блок `backend "s3"` из `infra/terraform-bootstrap/versions.tf`.

```bash
export TF_VAR_yc_token="$(yc iam create-token)"

terraform init
terraform plan
terraform apply
```

Пока bootstrap всё ещё использует локальный backend, нужно сохранить имя созданного bucket:

```bash
bucket="$(terraform output -raw state_bucket_name)"
```

Теперь можно вернуть блок `backend "s3"` из Git:

```bash
git restore versions.tf
```

После этого нужно получить созданные credentials из Lockbox:

```bash
export AWS_ACCESS_KEY_ID="$(
  yc lockbox payload get \
    --name mainplatform-tfstate-credentials \
    --key access_key
)"

export AWS_SECRET_ACCESS_KEY="$(
  yc lockbox payload get \
    --name mainplatform-tfstate-credentials \
    --key secret_key
)"
```

Перенос state в Object Storage:

```bash
terraform init -migrate-state "-backend-config=bucket=$bucket"

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset TF_VAR_yc_token
```

Это одноразовая операция. Удалять локальный `terraform.tfstate` можно только после успешной миграции и проверки `terraform state list`.

После миграции следующие запуски выполняются через helper:

```bash
cd ../..
./infra/scripts/terraform-with-backend.sh bootstrap init
./infra/scripts/terraform-with-backend.sh bootstrap plan
```

Bootstrap не удаляется вместе с виртуальными машинами: в нём хранится state основной инфраструктуры и доступ GitHub Actions.

## 3. Секрет Tailscale

В созданный Lockbox secret `mainplatform-tailscale-auth` нужно добавить entry:

```text
key: auth_key
value: <tailscale-auth-key>
```

Сам ключ в репозиторий не записывается.

## 4. Основная инфраструктура

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

В `terraform.tfvars` указываются:

- `cloud_id`;
- `folder_id`;
- пути к публичным SSH-ключам;
- временный внешний IP в `admin_cidr_blocks`.

Пример временного SSH-доступа:

```hcl
admin_cidr_blocks = ["203.0.113.10/32"]
```

Затем из корня репозитория:

```bash
cd ../..
./infra/scripts/terraform-with-backend.sh main init
./infra/scripts/terraform-with-backend.sh main plan
./infra/scripts/terraform-with-backend.sh main apply
```

Получить адреса созданных машин:

```bash
./infra/scripts/terraform-with-backend.sh main output
```

## 5. Inventory и Ansible

```bash
cd infra/ansible
cp inventory.example.ini inventory.ini
```

В `inventory.ini` нужно подставить публичные адреса control-plane и worker из `terraform output`.

Установить Ansible collection:

```bash
ansible-galaxy collection install -r requirements.yml
```

Получить Tailscale auth key из Lockbox:

```bash
export TAILSCALE_AUTH_KEY="$(
  yc lockbox payload get \
    --name mainplatform-tailscale-auth \
    --key auth_key
)"
```

Первый прогон устанавливает Kubernetes, базовые cluster addons, Vault,
Vault Secrets Operator и Argo CD. Vault bootstrap, мониторинг и приложение
на этом этапе пропускаются, потому что новый Vault ещё не инициализирован:

```bash
ANSIBLE_ROLES_PATH=roles ansible-playbook -i inventory.ini site.yml
```

После первого прогона подключиться к control-plane и инициализировать Vault:

```bash
kubectl get pods -n vault
kubectl exec -n vault vault-0 -- \
  vault operator init -key-shares=1 -key-threshold=1
```

Unseal key и root token нужно сохранить вне репозитория. Для стенда
используется один ключ, поэтому его потеря означает потерю доступа к данным
Vault.

В текущем стенде они хранятся как две отдельные entry `unseal_key` и
`root_token` в deletion-protected Lockbox secret
`mainplatform-vault-bootstrap`. Это break-glass хранилище: Kubernetes workloads
его не читают, а root token передаётся Ansible только через переменную окружения.
Для production вместо одного unseal key нужен auto-unseal через KMS и более
строгая процедура хранения recovery keys.

Разблокировать Vault:

```bash
kubectl exec -it -n vault vault-0 -- vault operator unseal
kubectl exec -n vault vault-0 -- vault status
```

На машине, с которой запускается Ansible, подготовить секреты. Значения не
записываются в inventory или Git:

```bash
read -rsp "Vault root token: " VAULT_ROOT_TOKEN && echo
export VAULT_ROOT_TOKEN

export MAINPLATFORM_POSTGRES_PASSWORD="$(openssl rand -hex 24)"
export GRAFANA_ADMIN_PASSWORD="$(openssl rand -hex 24)"

read -rsp "Telegram bot token: " TELEGRAM_BOT_TOKEN && echo
export TELEGRAM_BOT_TOKEN

read -rp "Telegram chat ID: " TELEGRAM_CHAT_ID
export TELEGRAM_CHAT_ID
```

Второй прогон создаёт Vault policies и Kubernetes auth roles, записывает
секреты, устанавливает мониторинг и передаёт приложение под управление
Argo CD:

```bash
ANSIBLE_ROLES_PATH=roles ansible-playbook \
  -i inventory.ini \
  site.yml \
  -e vault_bootstrap_enabled=true
```

После успешного выполнения удалить секреты из окружения:

```bash
unset VAULT_ROOT_TOKEN
unset MAINPLATFORM_POSTGRES_PASSWORD
unset GRAFANA_ADMIN_PASSWORD
unset TELEGRAM_BOT_TOKEN
unset TELEGRAM_CHAT_ID
unset TAILSCALE_AUTH_KEY
```

В результате playbook:

1. настраивает Tailscale subnet router;
2. устанавливает containerd и Kubernetes;
3. инициализирует control-plane;
4. подключает worker;
5. устанавливает Cilium, Vault, Vault Secrets Operator и остальные addons;
6. настраивает Kubernetes auth, policies и секреты в Vault;
7. синхронизирует секреты мониторинга через Vault Secrets Operator;
8. устанавливает мониторинг и Argo CD;
9. передаёт Argo CD описание приложения.

## 6. Закрытие публичного SSH

После одобрения маршрута `10.10.0.0/24` в Tailscale нужно проверить подключение к обеим нодам по приватным адресам.

Затем:

```hcl
admin_cidr_blocks = []
```

И повторно применить Terraform:

```bash
./infra/scripts/terraform-with-backend.sh main apply
```

После этого снаружи остаются открыты только HTTP и HTTPS, а SSH доступен через Tailscale.

## 7. Проверка кластера

На control-plane:

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get pods -n vault
kubectl get vaultauth,vaultstaticsecret -n monitoring
kubectl get applications -n argocd
kubectl get pods -n mainplatform
kubectl get certificate -n mainplatform
```

Ожидаемый результат:

- обе ноды имеют статус `Ready`;
- Vault имеет статус `Initialized=true`, `Sealed=false`;
- Vault Agent добавлен в backend, а Vault Secrets Operator синхронизирует
  секреты Grafana и Alertmanager;
- Argo CD Application имеет статусы `Synced` и `Healthy`;
- backend, frontend и PostgreSQL запущены;
- TLS-сертификат имеет статус `Ready=True`.

## 8. Проверка приложения

```bash
# frontend nginx
curl https://app.effervescence.ru/health

# FastAPI через frontend nginx
curl https://app.effervescence.ru/api/health
curl https://app.effervescence.ru/api/ready
```

Ingress направляет все внешние запросы во frontend Service. Поэтому `/health` проверяет frontend nginx, а запросы `/api/*` nginx проксирует в backend без префикса `/api`. Внутри backend endpoints по-прежнему называются `/health` и `/ready`.

В стенде используются отдельные домены для приложения, Grafana и Argo CD.

## Выпуск новой версии

Backend и frontend проходят отдельные CI pipeline:

```text
lint/test --> Docker build --> Trivy --> push SHA image в GHCR
```

После успешной сборки вручную запускается workflow `Promote image`:

1. выбирается `backend` или `frontend`;
2. указывается полный SHA нужного образа;
3. workflow проверяет образ;
4. SHA меняется в Kubernetes-манифесте;
5. изменение коммитится в `main`;
6. Argo CD синхронизирует кластер.

Для rollback запускается тот же workflow, но с SHA предыдущей рабочей версии.

## Удаление стенда

Чтобы виртуальные машины не расходовали грант:

```bash
./infra/scripts/terraform-with-backend.sh main destroy
```

Удаляется только основная инфраструктура: виртуальные машины, сеть и DNS-записи. Bootstrap с Object Storage, state, KMS, Lockbox и WIF остаётся.

Перед удалением стоит сохранить нужные скриншоты и данные приложения. `local-path` не переживает уничтожение worker-ноды.
