A responsive web monitoring, alerting, analytics, and reporting application for Coconut Surveillance™ for malaria elimination.

### Requirements

CouchDB -- installed locally or in Docker

### Development

1. Clone the Repository

```
git clone git@github.com:Coconut-Data/coconut-cloud.git
cd coconut-cloud/_attachments
```

2. Create the config.json file and edit its contents

```
cp config.defaults.json config.json
```

Then edit its contents to point at a database in CouchDB:

```
    {
        "targetUrl": "127.0.0.1",
        "targetDatabase": "zanzibar",
        "username": "admin",
        "password": "password"
    }
```

3. Install packages and start the app

```
npm install
npm start
```

Then go to http://127.0.0.1:8082


### Server Installation

Server installation instructions

1. Clone the Repository

```
cd /var/www
git clone git@github.com:Coconut-Data/coconut-cloud.git analytics
cd _attachments
npm run install-server
```

2. Create the config.json file and edit its contents

```
cp config.defaults.json config.json
```

3. Edit nginx config (Requires [nginx](https://www.nginx.com/)):

```
    location /analytics {
        alias /var/www/analytics/_attachments;
    }
```

4. (Optional) Add crontab to pull automatically

```
15 * * * * cd /var/www/analytics-dev; export GIT_SSH_COMMAND='ssh -i /root/.ssh/coconut_cloud_rsa'; git reset --hard origin/master; git pull origin master
```    
