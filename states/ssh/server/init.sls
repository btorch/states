include:
{#  - ssh.keys#}
  - diamond
  - nrpe
  - gsyslog

/etc/nagios/nrpe.d/ssh.cfg:
  file.managed:
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://ssh/server/nrpe.jinja2

openssh-server:
  pkg:
    - latest
  file:
    - managed
    - name: /etc/ssh/sshd_config
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://ssh/server/config.jinja2
    - require:
      - pkg: openssh-server
  service:
    - running
    - enable: True
    - name: ssh
    - watch:
      - pkg: openssh-server
      - file: openssh-server

ssh_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[sshd]]
        exe = ^\/usr\/sbin\/sshd,^\/usr\/lib\/sftp\-server


{% if not pillar['debug'] %}
/etc/gsyslog.d/ssh.conf:
  file:
    - managed
    - template: jinja
    - source: salt://ssh/server/gsyslog.jinja2
    - user: root
    - group: root
    - mode: 440
{% endif %}

extend:
{% if not pillar['debug'] %}
  gsyslog:
    service:
      - watch:
        - file: /etc/gsyslog.d/ssh.conf
{% endif %}
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/ssh.cfg
