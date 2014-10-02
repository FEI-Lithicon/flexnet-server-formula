{# Currently Debian only, no pillars or templates used #}

{% set version = '11.12.1.1' %}
{% set source_path = 'ftp://ftp.vsg3d.com/private/LICENSING/FLEXnet/11.12.1.1/flexnet-server_11.12.1.1_Linux-x86_64-gcc41.tar.gz' %}
{% set source_hash = 'md5=cdbd194c06227572bc2268509d75e866' %}
{% set tmp_path = '/tmp/flexnet/' %}
{% set install_path = '/opt/FNPLicenseServerManager' %}


/etc/init.d/lmadmin:
  file.managed:
    - source: 'salt://flexnet/files/init.d/lmadmin'
    - user: root
    - group: root
    - mode: 755

flexnet-server:
  pkg.installed:
    - name: gcc-multilib

  group.present:
    - name: lmadmin
    - system: True

  user.present:
    - name: lmadmin
    - fullname: FlexNet License Server User
    - gid_from_name: True
    - system: True
    - home: {{ install_path }}
    - createhome: False

{% if salt['grains.get']('flexnet-server') != version %}
  archive:
    - extracted
    - keep: True
    - name: {{ tmp_path }}
    - source: {{ source_path }}
    - source_hash: {{ source_hash }}
    - tar_options: v 
    - archive_format: tar

  file.managed:
    - name: {{ tmp_path }}
    - source: 'salt://flexnet/files/install'
    - file_mode: 700

  cmd.run:
    - name: './install'
    - cwd: {{ tmp_path }}

  grains.present:
    - name: flexnet-server
    - value: {{ version }}
{% endif %}


{{ install_path }}:
  file.directory:
    - makedirs: True
    - user: lmadmin
    - group: lmadmin
    - file_mode: 770
    - dir_mode: 770
    - recurse:
      - user
      - group
      - mode

{{  install_path ~ '/logs' }}:
   file.directory:
    - makedirs: True
    - user: lmadmin
    - group: lmadmin

lmadmin:
  service:
    - running
    - enable: True

