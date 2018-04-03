#!/usr/bin/env bash

#install MySQL via apt
sudo apt-get install mysql-server-5.7
sudo apt-get install libmysqld-dev

#setup MySQL db for cbrain
echo "Provide a password for the cbrain database:"
read CBRAIN_SQL_PASS
CBRAIN_SQL="create database cbrain; create user 'cbrain'@'localhost' identified by '$CBRAIN_SQL_PASS';  grant all on cbrain.* to 'cbrain'@'localhost';"
echo Enter MySQL root password
mysql -u root -p -e "$CBRAIN_SQL"

#install RVM
cd $HOME
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
\curl -sSL https://get.rvm.io | bash -s stable
source $HOME/.rvm/scripts/rvm

#install Ruby
rvm install 2.4.1
rvm use 2.4.1
rvm --default 2.4.1

#install cbrain codebase
cd $HOME
git clone https://github.com/aces/cbrain.git

#install gems
which bundle
if [ $? -eq 1 ] 
then
gem install bundler --no-ri --no-rdoc
fi

cd $HOME/cbrain/BrainPortal
bundle install

cd $HOME/cbrain/Bourreau
bundle install

cd $HOME/cbrain/BrainPortal
cd `bundle show sys-proctable`
rake install

cd $HOME/cbrain/BrainPortal
rake cbrain:plugins:install:all

cd $HOME/cbrain/Bourreau
rake cbrain:plugins:install:all

#BrainPortal setup
cd $HOME/cbrain/BrainPortal/config
cp database.yml.TEMPLATE database.yml
sed -i '0,/cbrain_db_name_here/s//cbrain/' database.yml
sed -i '0,/cbrain_db_user_name_here/s//cbrain/' database.yml 
sed -i "0,/cbrain_db_user_pw_here/s//$CBRAIN_SQL_PASS/" database.yml 

cd $HOME/cbrain/BrainPortal/config/initializers
cp config_portal.rb.TEMPLATE config_portal.rb
echo "Type a name for the rails app:"
read CBRAIN_APP_NAME
sed -i "s/simple_name/$CBRAIN_APP_NAME/" config_portal.rb

#BrainPortal rake tasks
cd $HOME/cbrain/BrainPortal
rake db:schema:load RAILS_ENV=production
rake assets:precompile
chomd -R go+rX public/assets
rake db:seed RAILS_ENV=production
rake db:sanity:check RAILS_ENV=production
