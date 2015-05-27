{# Currently Debian only, no pillars or templates used #}

{% set version = '11.12.1.1' %}
{% set source_path = 'ftp://ftp.vsg3d.com/private/LICENSING/FLEXnet/11.12.1.1/flexnet-server_11.12.1.1_Linux-x86_64-gcc41.tar.gz' %}
{% set source_hash = 'md5=cdbd194c06227572bc2268509d75e866' %}
{% set tmp_path = '/tmp/flexnet' %}
{% set base_path = '/opt' %}
{% set install_path = '/opt/FNPLicenseServerManager' %}
{% set tools_path = '/opt/FlexNetLicenseServerTools' %}


/lib/systemd/system/lmadmin.service:
  file.managed:
    - source: 'salt://flexnet/files/systemd/lmadmin.service'
    - user: root
    - group: root
    - mode: 755 
    - template: jinja
    - defaults:
      install_path: {{ install_path }}


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
    - pkgs:
      - gcc-multilib
      - lsb-base
      - lsb-core
      - lsb-release
      - lsb-security

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
flexnet-archive:
  archive:
    - extracted
    - keep: True
    - name: {{ tmp_path }}
    - source: {{ source_path }}
    - source_hash: {{ source_hash }}
    - tar_options: v 
    - archive_format: tar

salt://flexnet/files/install:
  cmd.wait_script:
    - cwd: {{ tmp_path }}
    - watch:
      - archive: flexnet-archive
    - require:
      - archive: flexnet-archive

FlexNetLicenseServerTools:
  file.rename:
    - source: {{ tmp_path ~ '/FlexNetLicenseServerTools' }}
    - name: {{ tools_path }}
    - force: True
    - makedirs: True
    - require:
      - archive: flexnet-archive

{{ install_path }}/mcslmd:
  file.copy:
    - source: {{ tools_path }}/mcslmd
    - force: True
    - user: lmadmin
    - group: lmadmin
    - mode: 770
    - require:
      - file: FlexNetLicenseServerTools

{{ install_path }}/mcslmd_libFNP.so:
  file.copy:
    - source: {{ tools_path }}/mcslmd_libFNP.so
    - force: True
    - user: lmadmin
    - group: lmadmin
    - mode: 770
    - require:
      - file: FlexNetLicenseServerTools

flexnet-version-grain:
  grains.present:
    - name: flexnet-server
    - value: {{ version }}
    - require:
      - file: FlexNetLicenseServerTools
      - file: {{ install_path }}/mcslmd_libFNP.so
      - file: {{ install_path }}/mcslmd

flexnet-clean-tmp:
  file.absent:
    - name: {{ tmp_path }}
    - require:
      - grains: flexnet-version-grain

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
    - require_in:
      - service: lmadmin

{{  install_path ~ '/logs' }}:
   file.directory:
    - makedirs: True
    - user: lmadmin
    - group: lmadmin
    - require_in:
      - service: lmadmin

lmadmin:
  service:
    - running
    - enable: True

