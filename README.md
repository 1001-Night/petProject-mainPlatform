# mainPlatform

Инфраструктура вокруг приложения с заметками - сквозной DevOps-проект: Kubernetes, CI/CD, IaC и мониторинг.

**`Стек: Kubernetes · Terraform · Ansible · Docker · GitHub Actions · Argo CD · Prometheus · Grafana · Loki · Yandex Cloud · PostgreSQL`**

![app.effervescence.ru](images/app-https.png)
> *Рабочее приложение на `app.effervescence.ru`*

---

Этот репозиторий является основным и в нём находится актуальный код всей инфраструктуры, а также приложения, подробнее про все важные инструменты связанные с инфраструктурой описано в других четырёх репозиториях:

### Навигация

- **CI/CD и GitOps** — https://github.com/1001-Night/mp-cicd
- **Kubernetes** — https://github.com/1001-Night/mp-kubernetes
- **Observability** — https://github.com/1001-Night/mp-observability
- **Infrastructure as Code** — https://github.com/1001-Night/mp-iac

---

### Запуск приложения

Для **локального запуска** требуется Docker и Docker Compose:
```bash
git clone https://github.com/1001-Night/petProject-mainPlatform.git
cd petProject-mainPlatform

cp .env.example .env
docker compose up -d --build
```

Процесс **развёртывания в облаке** описан в файле **[📄deployment.md](deployment.md)**. Если провайдер не Yandex.Cloud, некоторые действия могут разниться. 

### Что можно изменить/добавить

* **Отказоустойчивость** - сейчас 1 control-plane нода и 1 worker, PostgreSQL в одной реплике. Для HA нужны минимум 3 control-plane ноды, несколько worker-нод и внешний балансировщик вместо единственной точки входа.
* **Бэкапы** сейчас не настроены ни для PostgreSQL, ни для etcd. Добавил бы Velero для снапшотов кластера и pg_dump по расписанию для базы.
* **Секреты** сейчас разбросаны по двум местам: в Yandex Lockbox, Kubernetes Secrets в кластере. Можно добавить HashiCorp Vault в качестве единого источника правды вместо двух разных механизмов.
* **NetworkPolicy в Kubernetes** между namespace не настроены, а это значит любой под в кластере технически может достучаться до любого другого. Для безопасности добавил бы явные policy, ограничивающие трафик между namespace.