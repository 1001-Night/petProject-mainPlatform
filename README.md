Nothing yet

для запуска docker-compose.yml:
```
cp .env.example .env
docker compose up -d --build
```

terraform локально:
```
$env:YC_TOKEN = yc iam create-token
$env:TF_VAR_yc_token = $env:YC_TOKEN
```

kubectl локально:
```
$env:KUBECONFIG = "C:\Users\leont\Desktop\projects\petproject\kubeconfig-mainplatform"
```

другое:
```
gh secret set SECRET_NAME --body
ssh -o StrictHostKeyChecking=accept-new user@ip true
ANSIBLE_ROLES_PATH=roles ansible-playbook -i inventory.ini site.yml
```