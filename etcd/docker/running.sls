# -*- coding: utf-8 -*-
# vim: ft=yaml
{% from "etcd/map.jinja" import etcd with context -%}

   {% if etcd.docker.stop_local_etcd_service_first %}
include:
  - etcd.service.stopped
   {% endif %}

#centos7 fix https://github.com/saltstack-formulas/etcd-formula/issues/19 
etcd-docker-compose-request-conflict-resolution:
  pip.installed:
    - names:
      - requests {{ etcd.docker.pip_requests_version_wanted }}
    - exists_action: i
    - reload_modules: True
    - onlyif: {{ grains.os_family == 'RedHat' }}

{% for pkg in etcd.docker.packages -%}
  {% if pkg %}
etcd-docker-{{ pkg }}-package:
  pkg.installed:
    - name:  {{ pkg }}
    - require:
      - pip: etcd-docker-compose-request-conflict-resolution
    - require_in:
      - docker_container: run-etcd-dockerized-service
    - onfail_in:
      - pip: etcd-docker-python-pip-install
  {% endif %}
{% endfor %}

etcd-docker-python-pip-install:
  pip.installed:
    - name: 'docker'
    - reload_modules: True
    - exists_action: i
    - force_reinstall: False
    - require_in:
      - docker_container: run-etcd-dockerized-service

etcd-ensure-docker-service:
  service.running:
    - name: docker
    - require_in:
      - docker_container: run-etcd-dockerized-service

run-etcd-dockerized-service:
  docker_container.running:
       {% if etcd.docker.version %}
    - image: {{ etcd.docker.image }}:{{ etcd.docker.version }}
       {% else %}
    - image: {{ etcd.docker.image }}
       {% endif %}
    - command: {{ etcd.docker.cmd }}
    - binds:
        {% for volume in etcd.docker.volumes %}
      - {{ volume }}
        {% endfor %}
    - port_bindings:
        {% for port in etcd.docker.ports %}
      - {{ port }}
        {% endfor %}
