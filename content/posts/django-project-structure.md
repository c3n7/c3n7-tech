---
title: "Django Project Structure"
description: "An overview of Django projects."
date: "2020-10-30T17:54:41+03:00"
author: "Timothy Karani"
authorTwitter: "c3n7_luc" #do not include @
tags: ["django", "python"]
keywords: ["django", "python"]
showFullContent: false
draft: false
---

Today I aim to make you know more about how a Django project is structured. We'll start with how to do initial setup, move on to describing how Django apps look like, talk about the request/response cycle, and templates

## Initial Setup

We first have to setup the environment before we can create a Django project. You have to install Python then create a virtual environment. There are several ways of creating a virtual environment. Python 3.x has this functionality inbuilt:

```shell
$ python -m venv myvenv
```

The `virtualenv` Python package can do the same thing. It has to be installed (ideally this only has to be done once).

```shell
$ pip install virtualenv
$ virtualenv myvenv
```

Activate the virtual environment. On linux this would be done like:

```shell
$ source myvenv/bin/activate
```

Create a project and `cd` into it:

```shell
$ django-admin startproject helloworld
$ cd helloworld
```

# A Django Project

Our project now looks like this:

```plaintext
helloworld
├── db.sqlite3
├── helloworld
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── manage.py
```

The outer level `helloworld` directory is a container for the project. This directory's name does not matter to Django so you cam change it later on.

The "inner" helloworld is the actual python package for your project. Its name is the Python package name you'll need to use to import anything inside it. It has files like `settings.py` (which contains settings/configurations for the project), and `urls.py` (which contains URL declarations for the project).

`manage.py` is used to execute several Django commands for example, starting the development server, creating superuser account, and creating new apps among others.

## Django Apps

A Django project is structured into apps. Creating an new ap cam be done like:

```shell
$ python manage.py startapp sampleapp
```

Our folder now looks like:

```plaintext
helloworld
├── db.sqlite3
├── helloworld
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── manage.py
└── sampleapp
    ├── __init__.py
    ├── admin.py
    ├── apps.py
    ├── migrations
    │   └── __init__.py
    ├── models.py
    ├── tests.py
    └── views.py
```

A new directory with the name passed to `startapp` is created, in our case, `sampleapp`. In it there are these files: - `admin.py` a configuration file for the built in Django Admin app. - `apps.py` is a configuration file for the app itself. - `migrations/` keeps track of any changes to the app's `models.py`. - `models.py` is where we define our database models which Django will translate into database tables. - `tests.py` contains the app's tests - `views.py` handles the request/response logic for our app.
To make the Django project "aware" of the new app we've added, we also have to add it in `settings.py`

```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'sampleapp.apps.SampleappConfig', # new
]
```

## Django request/response cycle

When a user navigates to our project's URL, a request/response sequence is initiated. It can visualized as:

_URL_ -> _View_ -> _Model_ (if required) -> _Template_

- _URL_ - you type `localhost:8000`, the default route is loaded by Django. When you enter `localhost:8000/about`, the about route is loaded by Django. The configured view for the route is loaded.
- _View_ - the view configured to be shown for the particilar route is loaded. The view retreives data from the database, if required, formats it and presents it (for use in the template).
- _Template_ - this is the markup that receives the formatted data from the view. The template is rendered to what thee user finally sees on the browser.

## Templates

An app ideally has its templates. By default, Django looks for the template within an app. For example, for our app `sampleapp`, Django looks for the templates in;

```plaintext
└── sampleapp
    ├── templates
    │  	 └── sampleapp
    │        ├── home.html
    │        └── about.html
    └── ......
```

This repetitive structure is the default behavior that Django works with. It is, however, not the only workflow.

You could create a custom directory for your template in the root directory and put your templates in it.

```shell
$ mkdir mytemplates
$ touch mytemplates/home.html
```

Our project directory now looks like

```plaintext
helloworld
├── db.sqlite3
├── helloworld
│      └── ........
├── mytemplates
│      └── home.html
├── manage.py
└── sampleapp
         └── .......
```

Since this is a custom directory, we have to make Django know it. We do this in `settings.py`

```python
TEMPLATES = [
    {
        ...
        'DIRS': [os.path.join(BASE_DIR, 'mytemplates')], # new
        ...
    },
]
```

## End

Thank you for reading through the document.
