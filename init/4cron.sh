rvm_bin_path=/usr/local/rvm/bin
GEM_HOME=/usr/local/rvm/gems/ruby-2.2.4
IRBRC=/usr/local/rvm/rubies/ruby-2.2.4/.irbrc
MY_RUBY_HOME=/usr/local/rvm/rubies/ruby-2.2.4
rvm_path=/usr/local/rvm
rvm_prefix=/usr/local
PATH=/usr/local/rvm/gems/ruby-2.2.4/bin:/usr/local/rvm/gems/ruby-2.2.4@global/bin:/usr/local/rvm/rubies/ruby-2.2.4/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/rvm/bin
rvm_version=1.27.0 (latest)
GEM_PATH=/usr/local/rvm/gems/ruby-2.2.4:/usr/local/rvm/gems/ruby-2.2.4@global
RUBY_VERSION=ruby-2.2.4

*/5 * * * * cd /home/mihailov.s/miker_p2p;ruby peer_cleanup.cron.rb >> /home/mihailov.s/miker_p2p/var/log/peer_cleanup.cron.log 2>&1