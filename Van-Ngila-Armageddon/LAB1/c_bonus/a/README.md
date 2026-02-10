# Projet 1C Bonus-A : Infrastructure AWS Privée avec VPC Endpoints

## 📋 Description du Projet
Ce projet implémente une infrastructure AWS entièrement privée où une instance EC2 dans un sous-réseau privé communique avec les services AWS via des VPC endpoints, sans besoin de NAT Gateway ou d'accès internet public.

## 🎯 Objectifs Réalisés
- ✅ Instance EC2 sans IP publique
- ✅ Connexion via Session Manager (pas de SSH)
- ✅ Communication AWS via VPC Interface Endpoints
- ✅ Politiques IAM de moindre privilège
- ✅ Logs CloudWatch via endpoints privés

## 🏗️ Architecture

### Services AWS Utilisés
- **EC2** : Instance privée avec SSM Agent
- **RDS** : Base de données MySQL privée
- **VPC Endpoints** :
  - Interface: SSM, EC2Messages, SSMMessages, Logs, Secrets Manager, KMS, EC2 API
  - Gateway: S3
- **IAM** : Rôles et politiques restrictives
- **Secrets Manager** : Stockage des credentials RDS
- **CloudWatch** : Logs et monitoring

### Diagramme d'Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                         VPC Privée                          │
│                                                             │
│  ┌──────────┐      ┌──────────────┐      ┌─────────────┐   │
│  │  EC2     │──────│ VPC Endpoints├──────│  Services   │   │
│  │ Privée   │      │  Interface   │      │   AWS       │   │
│  └──────────┘      └──────────────┘      └─────────────┘   │
│         │                    │                    │         │
│         └────────────────────┼────────────────────┘         │
│                              │                              │
│                     ┌────────▼────────┐                     │
│                     │ VPC Endpoint    │                     │
│                     │    Gateway S3   │                     │
│                     └─────────────────┘                     │
│                                                             │
│  ┌──────────┐                                              │
│  │   RDS    │                                              │
│  │  MySQL   │                                              │
│  └──────────┘                                              │
└─────────────────────────────────────────────────────────────┘
```

## ⚠️ Problèmes Rencontrés et Solutions

### 1. **VPC Endpoints dans la même Zone de Disponibilité**
**Problème** : `DuplicateSubnetsInSameZone` - Les endpoints Interface doivent être dans des AZ différentes.
**Solution** : Répartir les subnets sur 3 AZ différentes ou utiliser seulement 2 subnets.

### 2. **SSM Agent non installé sur Amazon Linux 2023**
**Problème** : L'instance n'apparaissait pas dans Session Manager.
**Solution** : Ajouter l'installation manuelle du SSM Agent dans le `user_data` :
```bash
dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
```

### 3. **Absence de Security Group pour les VPC Endpoints**
**Problème** : Impossible de se connecter aux endpoints.
**Solution** : Créer un SG dédié avec règle ingress port 443 depuis le SG EC2.

### 4. **Timeout des commandes AWS CLI EC2**
**Problème** : `Connect timeout on endpoint URL: "https://ec2.ap-northeast-1.amazonaws.com/"`
**Solution** : Ajouter un VPC endpoint pour l'API EC2.

### 5. **IAM Policies insuffisantes**
**Problème** : Erreurs d'authentification SSM.
**Solution** : Ajouter les permissions manquantes :
- `kms:DescribeKey`
- `ssm:UpdateInstanceInformation`
- `ssm:ListInstanceAssociations`

## 🛠️ Configuration Terraform

### Structure des Modules
```
modules/
├── network/          # VPC, Subnets, Route Tables
├── security/         # Security Groups
├── iam/              # Rôles et politiques IAM
├── ec2/              # Instance EC2
├── rds/              # Base de données RDS
├── vpc_endpoints/    # VPC Endpoints
├── cloudwatch/       # Alarms et Logs
└── config-store/     # SSM Parameter Store
```

### Variables Clés
```terraform
# terraform.tfvars
region = "ap-northeast-1"
env_prefix = "lab-1c"
vpc_cidr_block = "172.17.0.0/16"

# Subnets privés dans 3 AZ différentes
private_subnet_cidr_1 = "172.17.11.0/24"  # AZ A
private_subnet_cidr_2 = "172.17.21.0/24"  # AZ C  
private_subnet_cidr_3 = "172.17.13.0/24"  # AZ D

avail_zone_1 = "ap-northeast-1a"
avail_zone_2 = "ap-northeast-1c"
avail_zone_3 = "ap-northeast-1d"
```

## 📝 Vérification de l'Implémentation

### Commande 1 : Vérifier que l'EC2 est privée
```bash
aws ec2 describe-instances \
  --instance-ids i-09c49ba0794b979d3 \
  --query "Reservations[].Instances[].PublicIpAddress"
# Résultat attendu : []
```

### Commande 2 : Vérifier les VPC Endpoints
```bash
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=vpc-07d941f8b5a5ad8de" \
  --query "VpcEndpoints[].ServiceName"
# Doit inclure : ssm, ec2messages, ssmmessages, logs, secretsmanager, s3
```

### Commande 3 : Vérifier Session Manager
```bash
aws ssm describe-instance-information \
  --query "InstanceInformationList[].InstanceId"
# Doit retourner l'ID de votre instance
```

### Commande 4 : Vérifier l'accès aux config stores
```bash
aws ssm get-parameter --name /lab/db/endpoint
aws secretsmanager get-secret-value --secret-id lab-1c/rds/mysql
```

### Commande 5 : Vérifier CloudWatch Logs
```bash
aws logs describe-log-streams --log-group-name /aws/ec2/lab-rds-app
```

## 🔒 Bonnes Pratiques Implémentées

### Sécurité
- **Moindre privilège** : Policies IAM restrictives
- **Réseau privé** : Pas d'IP publique, pas de NAT
- **Chiffrement** : Secrets Manager avec KMS
- **Audit** : Logs CloudWatch

### Résilience
- **Multi-AZ** : Subnets répartis sur 3 zones
- **Health checks** : Endpoints de santé dans l'application
- **Auto-recovery** : Services systemd avec restart

### Opérationnel
- **Infra as Code** : Terraform pour reproductibilité
- **Configuration centralisée** : SSM Parameter Store
- **Monitoring** : CloudWatch Agent intégré

## 🚀 Déploiement

### Initialisation
```bash
terraform init
```

### Planification
```bash
terraform plan -var-file="lab-1c.tfvars"
```

### Application
```bash
terraform apply -var-file="lab-1c.tfvars"
```

### Destruction
```bash
terraform destroy -var-file="lab-1c.tfvars"
```

## 📊 Validation des Résultats

### ✅ Points Validés
1. **Instance EC2 privée** : ✓ Aucune IP publique
2. **VPC Endpoints fonctionnels** : ✓ 7 endpoints créés
3. **Session Manager opérationnel** : ✓ Instance visible et connectable
4. **Accès aux config stores** : ✓ SSM et Secrets Manager accessibles
5. **CloudWatch Logs** : ✓ Groupe de logs accessible via endpoint

### 🔍 Points d'Attention
- Les logs CloudWatch peuvent prendre quelques minutes à apparaître
- L'agent SSM peut nécessiter 2-3 minutes pour s'enregistrer
- Vérifier les Security Groups après chaque modification

## 🏆 Conformité au Cahier des Charges

| Exigence | Statut | Commentaire |
|----------|--------|-------------|
| EC2 sans IP publique | ✅ | `associate_public_ip_address = false` |
| Pas de SSH | ✅ | Utilisation exclusive de Session Manager |
| VPC Endpoints | ✅ | SSM, EC2Messages, SSMMessages, Logs, Secrets Manager, S3 |
| IAM restrictif | ✅ | Policies spécifiques par ressource |
| Logs CloudWatch | ✅ | Via endpoint VPC |
| Application Flask-RDS | ✅ | Connexion via Secrets Manager |

## 📚 Leçons Apprises

### À Éviter
1. **Ne pas supposer que SSM Agent est pré-installé** (Amazon Linux 2023)
2. **Ne pas oublier le Security Group pour les VPC Endpoints**
3. **Ne pas mettre plusieurs subnets dans la même AZ pour les endpoints Interface**
4. **Ne pas négliger les permissions KMS pour Secrets Manager**

### À Faire Systématiquement
1. **Tester chaque endpoint individuellement** avec curl
2. **Vérifier les logs SSM Agent** pour le debugging
3. **Utiliser `filebase64()` pour user_data** au lieu de `file()`
4. **Ajouter des health checks** dans l'application

## 🔗 Références
- [AWS VPC Endpoints Documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [SSM Agent Installation Guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Projet réalisé avec succès** - Tous les objectifs du bonus 1C ont été atteints avec une infrastructure sécurisée, résiliente et conforme aux meilleures pratiques AWS.