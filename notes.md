# testdriven.io
* Deploying Django to AWS ECS with Terraform
### Michael Herman, J-O Eriksson
* [Terraform, django, docker](https://testdriven.io/blog/deploying-django-to-ecs-with-terraform/?ref=morioh.com&utm_source=morioh.com)
* [Dockerizing Django, Postgres Gunicorn and Nginx](https://testdriven.io/blog/dockerizing-django-with-postgres-gunicorn-and-nginx/)
* [Django, Celery and Dockery](https://testdriven.io/blog/django-celery-periodic-tasks/)

### My aws account
[secret](./secret.md)
### Objectives
1. Explain Terraform
1. Use ECR Docker image registry to store images
1. Terraform config
1. Deploiy Django to a cluster
1. Boto3 to update an ECS Service
1. RDS
209. Https listener for load balancer
## Explain Terraform -- Overview and setup
This tut will cover
1. Networking:
    * VPC
    * Public and private subnets
    * Routing tables
    * Internet Gateway
    * Key Pairs
1. Security Groups
1. Load Balancers, Listeners, and Target Groups
1. IAM Roles and Policies
1. ECS:
    * Task Definition (with multiple containers)
    * Cluster
    * Service
1. Launch Config and Auto Scaling Group
1. Health Checks and Logs

### Setup
```
$ mkdir django-ecs-terraform && cd django-ecs-terraform
$ mkdir app && cd app
$ python3.10 -m venv env
$ source env/bin/activate

(env)$ pip install django==3.2.9
(env)$ django-admin startproject hello_django .
(env)$ python manage.py migrate
(env)$ python manage.py runserver
```
* Edit settings.py
    * DEBUG=True
    * ALLOWED_HOSTS = [*]

#### File struct
* .gitignore
* app
    * Dockerfile
    * manage.py
    * requirements.txt
    * hello_django
        * wsgi.py
        * ...
        
## Use ECR Docker image registry to store images
### Docker file
* use python:3.9.0-slim-buster in [Dockerfile](app/Dockerfile)

```
docker build -t django-ecs .

docker run -p 8007:8000 --name django-test django-ecs gunicorn hello_django.wsgi:application --bind 0.0.0.0:8000
```
http://localhost:8007

docker stop django-test
docker rm django-test


* Using the AWS console for this. Login then 
    * http://console.aws.amazon.com/ecr
        * Add a new repository called django-app. Tags Are mutable (default)
    * build it replacing account id and region
```
<!-- docker build -t <AWS_ACCOUNT_ID>.dkr.ecr.us-west-1.amazonaws.com/django-app:latest . -->
docker build -t 760662774875.dkr.ecr.us-east-2.amazonaws.com/django-app:latest .
``` 
* Authenticate / login  using aws cli
```
aws ecr get-login-password --region us-west-2
aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {aws_account_id}.dkr.ecr.{region}.amazonaws.com
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 760662774875.dkr.ecr.us-east-2.amazonaws.com
```
* Power shell version
```
(Get-ECRLoginCommand).Password | docker login --username AWS --password-stdin {aws_account_id}.dkr.ecr.{region}.amazonaws.com
(Get-ECRLoginCommand).Password | docker login --username AWS --password-stdin 760662774875.dkr.ecr.us-east-2.amazonaws.com
```
* Push the image
```
docker push {AWS_ACCOUNT_ID}.dkr.ecr.{region}.amazonaws.com/django-app:latest
docker push 760662774875.dkr.ecr.us-east-2.amazonaws.com/django-app:latest
```

##  Terraform config
* terraform
[01_provider.tf](terraform/01_provider.tf)
* Create env variables: (vars in [secret](./secret.md))
```
export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
```
* [variables.tf](./terraform/variables.tf)

### Terraform Resources
1. Networking:
    * VPC
    * Public and private subnets
    * Routing tables
    * Internet Gateway
    * Key Pairs
1. Security Groups
1. Load Balancers, Listeners, and Target Groups
1. IAM Roles and Policies
1. ECS:
    * Task Definition (with multiple containers)
    * Cluster
    * Service
1. Launch Config and Auto Scaling Group
1. Health Checks and Logs

### Terraform files

1. [02_network.tf](./terraform/02_network.tf)
    * also added to [variables.tf](./terraform/variables.tf)
1. [03_securitygroupls.tf](./terraform/03_securitygroups.tf)
1. [04_loadbalancer.tf](./terraform/04_loadbalancer.tf)
    * also added to [variables.tf](./terraform/variables.tf)
1. [05_iam.tf](./terraform/05_iam.tf)
    * [ecs-role.json](./terraform/policies/ecs-role.json)
    * [ecs-instance-role-policy.json](./terraform/policies/ecs-instance-role-policy.json)
    * [ecs-service-role-policy.json](./terraform/policies/ecs-service-role-policy.json)
1. [06_logs.tf](./terraform/06_logs.tf)
    * also added to [variables.tf](./terraform/variables.tf)
1. [07_keypair.tf](./terraform/07_keypair.tf)
    * also added to [variables.tf](./terraform/variables.tf)
    * The amis variable must match the region (aka us-east-2)
    * ***Note, this location in variables.tf will need to be verified, changed. created***
1. [08_ecs.tf](./terraform/08_ecs.tf)
    * ecs.user_data is a script to capture the cluster name into a file, allowing it to be discovered by the cluster (seems kind of hacky)
    * [service template django_app.json.tpl](./terraform/templates/django_app.json.tpl)
    * also added to [variables.tf](./terraform/variables.tf)
    * ***Note that variables include t2.micro***
    * ***Configure the url as done above in login stuff:***
        * account id  and region in docker_image_url_django variable
1. [09_auto_scaling.tf](./terraform/09_auto_scaling.tf)
    * also added to [variables.tf](./terraform/variables.tf)


## Deploiy Django to a cluster

* add Middleware
    * [Health check middle ware](./app/hello_django/middleware.py)
    * and in settings MIDDLEWARE ```'hello_django.middleware.HealthCheckMiddleware',```
```
docker build -t django-ecs .
docker run \
    -p 8008:8000 \
    --name django-test \
    django-ecs \
    gunicorn hello_django.wsgi:application --bind 0.0.0.0:8000
```
check localhost:8008/ping
stop it 
* Updat ECR
```
docker build -t 760662774875.dkr.ecr.us-east-2.amazonaws.com/django-app:latest .
docker push 760662774875.dkr.ecr.us-east-2.amazonaws.com/django-app:latest
```

* Script to update task definition
    * [update-ecs.py](./deploy/update-ecs.py)
    * pip install boto3 click

```
export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="us-east-2"
python update-ecs.py --cluster=production-cluster --service=production-service
```

"production-alb-548003530.us-east-2.elb.amazonaws.com






