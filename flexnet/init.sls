{# Currently Debian only, no pillars or templates used #}

{% set version = '11.12.1.1' %}
{% set source_path = 'ftp://ftp.vsg3d.com/private/LICENSING/FLEXnet/11.12.1.1/flexnet-server_11.12.1.1_Linux-x86_64-gcc41.tar.gz' %}
{% set source_hash = 'md5=cdbd194c06227572bc2268509d75e866' %}
{% set tmp_path = '/tmp/flexnet/' %}
{% set install_path = '/opt/FNPLicenseServerManager' %}
{% set tools_path = '/opt/FlexNetLicenseServerTools' %}


/etc/init.d/lmadmin:
  file.managed:
    - source: 'salt://flexnet/files/init.d/lmadmin'
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - defaults:
      install_path: {{ install_path }}

/etc/profile.d/flexnet.sh:
    file.managed:
      - source: 'salt://flexnet/files/profile.d/flexnet.sh'
      - user: root
      - group: root
      - mode: 755
      - template: jinja
      - defaults:
        tools_path: {{ tools_path }}



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

  cmd.script:
    - source: 'salt://flexnet/files/install'
    - cwd: {{ tmp_path }}

  grains.present:
    - name: flexnet-server
    - value: {{ version }}

FlexNetLicenseServerTools:
  - source: {{ tmp_path }}/FlexNetLicenseServerTools
  - force: True
  - user: lmadmin
  - group: lmadmin
  - mode: 770

{{ install_path }}/mcslmd:
  - source: {{ tmp_path }}/FlexNetLicenseServerTools/mcslmd
  - force: True
  - user: lmadmin
  - group: lmadmin
  - mode: 770

{{ install_path }}/mcslmd:_libFNP.so:
  - source: {{ tmp_path }}/FlexNetLicenseServerTools/mcslmd_libFNP.so
  - force: True
  - user: lmadmin
  - group: lmadmin
  - mode: 770
  
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

