# testdriven.io
### Michael Herman, J-O Eriksson
* [Terraform, django, docker](https://testdriven.io/blog/deploying-django-to-ecs-with-terraform/?ref=morioh.com&utm_source=morioh.com)
* [Dockerizing Django, Postgres Gunicorn and Nginx](https://testdriven.io/blog/dockerizing-django-with-postgres-gunicorn-and-nginx/)
* [Django, Celery and Dockery](https://testdriven.io/blog/django-celery-periodic-tasks/)

### Objectives
1. Explain Terraform
1. Use ECR Docker image registry to store images
1. Terraform config
1. Deploiy Django to a cluster
1. Boto3 to update an ECS Service
1. RDS
209. Https listener for load balancer


### Going to set up the following in Terraform
* Network
    * VPC
    * Public and private subnet
    * Routing tables
    * Internet Gateway
    * Key Pairs
* Security Groups
* Load Balancers, Listeners, and Target Groups
* IAM Roles and Policies
* ECS
    * Task definition
    * Cluster
    * Service
* Launch Config and Auto Scaling Group
* RDS
* Health Checks and Logs

### Elastic Contaier Service is a fully managed thing to 
Recommends Doing it on the console prior to Terraform
## Setup
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

NOTE:
tut asked for Django 3.2.9. Latest stabel is 4.0.2. Gonna leave it there till when/if there is a conflict

### File struct under app
* hello_django
    * wsgi.py
    * ...
* Dockerfile
* manage.py
* requirements.txt
### Docker file
* use python:3.9.0-slim-buster in [Dockerfile](app/Dockerfile)

```
docker build -t django-ecs .

docker run -p 8007:8000 --name django-test django-ecs gunicorn hello_django.wsgi:application --bind 0.0.0.0:8000
```
http://localhost:8007

$ docker stop django-test
$ docker rm django-test
