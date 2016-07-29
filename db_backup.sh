BACKUP_PATH_CONTAINER=/shared/backups
BACKUP_PATH_LOCAL=/var/discourse/shared/standalone/backups
BACKUP_FILE=discourse-backup.sql
REMOTE_HOST=halfbreed@104.196.158.216

echo 'Running pg_dump'
sudo docker exec -u discourse app bash -c \
  "pg_dump -xOf $BACKUP_PATH_CONTAINER/$BACKUP_FILE -d discourse -n public && \
  cd $BACKUP_PATH_CONTAINER && \
  gzip -9f $BACKUP_FILE"

echo 'Transferring DB dump'
scp $BACKUP_PATH_LOCAL/$BACKUP_FILE.gz $REMOTE_HOST:$BACKUP_PATH_LOCAL

echo 'Wiping DB on remote host'
ssh -t $REMOTE_HOST \
  "sudo docker exec -u postgres app bash -c 'psql discourse \
<<END
  DROP SCHEMA public CASCADE;
  CREATE SCHEMA public;
  ALTER SCHEMA public OWNER TO discourse;
  CREATE EXTENSION IF NOT EXISTS hstore;
  CREATE EXTENSION IF NOT EXISTS pg_trgm;
END' && \

  cd $BACKUP_PATH_LOCAL && gunzip -f $BACKUP_FILE.gz && \

  echo 'Restoring DB' && \
  sudo docker exec -u discourse app bash -c \
    'psql -d discourse -f $BACKUP_PATH_CONTAINER/$BACKUP_FILE > /dev/null && \
    cd /var/www/discourse && \
    echo 'Running db:migrate' && \
    RAILS_ENV=production bundle exec rake db:migrate' > /dev/null && \
    echo 'Restarting app' && \
    sudo /var/discourse/launcher restart app > /dev/null" 
