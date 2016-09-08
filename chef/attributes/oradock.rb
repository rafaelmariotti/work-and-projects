#backup and data settings
default['backup']['directory'] = '/backup'
default['backup']['device']    = '/dev/sdc'
default['data']['directory']   = '/data'
default['data']['device']      = '/dev/sdd'

#python settings
default['pyenv']['version']   = '3.5.1'
default['pyenv']['root_path'] = '/root/.pyenv'
default['pyenv']['modules']   = 'boto docopt docker-py'

#yum settings
default['yum']['install'] = 'wget.x86_64','git.x86_64','patch.x86_64','gcc44.x86_64','zlib.x86_64','zlib-devel.x86_64','bzip2.x86_64','bzip2-devel.x86_64','sqlite.x86_64','sqlite-devel.x86_64','openssl.x86_64','openssl-devel.x86_64'
