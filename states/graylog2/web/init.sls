include:
  - ruby
  - nrpe

{% set web_root_dir = '/opt/graylog2-web-interface-' + pillar['graylog2']['web']['version'] %}

{% for filename in ('config', 'email', 'indexer', 'mongoid') %}
graylog2-web-{{ filename }}:
  file:
    - managed
    - name: {{ web_root_dir }}/config/{{ filename }}.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - source: salt://graylog2/web/{{ filename }}.jinja2
{% endfor %}

graylog2-web_logdir:
  file:
    - directory
    - name: /var/log/graylog2/
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

graylog2-web_logrotate:
  file:
    - managed
    - name: /etc/logrotate.d/graylog2-web
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - source: salt://graylog2/web/logrotate.jinja2

graylog2-web:
  gem:
    - installed
    - name: bundler
    - require:
      - pkg: ruby
  archive:
    - extracted
    - name: /opt/
    - source: https://github.com/downloads/Graylog2/graylog2-web-interface/graylog2-web-interface-{{ pillar['graylog2']['server']['version'] }}.tar.gz
    - source_hash: {{ pillar['graylog2']['web']['checksum'] }}
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ web_root_dir }}
  cmd:
    - run
    - name: bundle install
    - cwd: {{ web_root_dir }}
    - watch:
      - archive: graylog2-web
  file:
    - managed
    - name: /etc/init/graylog2-web.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - source: salt://graylog2/web/upstart.jinja2
  service:
    - running
    - require:
      - file: graylog2-web
      - file: graylog2-web_logdir
    - watch:
      - archive: graylog2-web
{% for filename in ('config', 'email', 'indexer', 'mongoid') %}
      - file: graylog2-web-{{ filename }}
{% endfor %}

/etc/nagios/nrpe.d/graylog2-web.cfg:
  file.managed:
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 600
    - source: salt://graylog2/web/nrpe.jinja2

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/graylog2-web.cfg
