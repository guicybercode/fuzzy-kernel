# Terraform Infrastructure

Infraestrutura como código para deploy do Microkernel IoT Platform na AWS.

## Requisitos

- Terraform >= 1.0
- AWS CLI configurado
- Credenciais AWS com permissões adequadas

## Variáveis

Criar arquivo `terraform.tfvars`:

```hcl
aws_region      = "us-east-1"
environment     = "production"
database_url    = "postgresql://user:pass@host:5432/db"
secret_key_base = "your-secret-key-base"
```

## Deploy

1. Inicializar Terraform:
```bash
terraform init
```

2. Planejar mudanças:
```bash
terraform plan
```

3. Aplicar:
```bash
terraform apply
```

4. Obter outputs:
```bash
terraform output load_balancer_dns
```

## Destruir

```bash
terraform destroy
```

## Estrutura

- **main.tf**: Recursos principais (ECS, VPC, Load Balancer)
- **variables.tf**: Variáveis de entrada
- **outputs.tf**: Outputs do Terraform

## Recursos Criados

- ECS Cluster (Fargate)
- Application Load Balancer
- VPC com subnets públicas e privadas
- Security Groups
- CloudWatch Log Groups
- ECS Services e Task Definitions

