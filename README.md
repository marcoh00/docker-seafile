# What is this?

This is a [Seafile](https://www.seafile.com) image for Docker. Seafile is a self-hostable Dropbox alternative.

# Interactive shell sessions

First of all, be aware that this image will drop you to an interactive shell from time to time. It is important to start the container using the interactive and tty flags (-it) for this to work. Interactive shell happens:

- On first start, so you can run the installer scripts from there. *Please do not forget to run Seafile after initial configuration* so you can create an administrator account.
- After every upgrade, so you can upgrade your installation.

Just run 'seafile-updated' when you are done.

# How to run

The image exposes a few ports and will need you to mount some volumes for it to work. You can run it like this:

```
/usr/bin/docker run --name seafile -p 8000:8000 -p 8080:8080 -p 8082:8082 -p 9000:9000 -v "{{ ccnetpath }}:/seafile/ccnet" -v "{{ confpath }}:/seafile/conf" -v "{{ datapath }}:/seafile/seafile-data" -v "{{ logpath }}:/seafile/logs" marcoh00/seafile
```

You will still need some kind of reverse proxy to use this image as Seahub will expose the FastCGI interface. See a sample nginx configuration below.

# Ports

- 8000: Seahub FastCGI
- 8080: WebDAV (if configured in conf/seafdav.conf, see Seafile's documentation)
- 8082: Fileserver
- 9000: Python SimpleHTTPServer, serving static Seahub content

# Volumes

- /seafile/ccnet: ccnet configuration
- /seafile/conf: Seafile & Seahub configuration
- /seafile/seafile-data: Actual data
- /seafile/logs: Seafile logs & output

# Sample nginx configuration

As already said, you will need to configure a reverse proxy in front of Seafile & Seahub. Here is an example for nginx:

```
server {
    listen 80;
    server_name seafile.domain.com;
    proxy_set_header X-Forwarded-For $remote_addr;
    
    client_max_body_size 0;
    
    location /robots.txt {
        return 200 "User-agent: *\nDisallow: /\n";
    }
    
    location / {
        fastcgi_pass    seafile:8000;
        fastcgi_param   SCRIPT_FILENAME     $document_root$fastcgi_script_name;
        fastcgi_param   PATH_INFO           $fastcgi_script_name;

        fastcgi_param   SERVER_PROTOCOL     $server_protocol;
        fastcgi_param   QUERY_STRING        $query_string;
        fastcgi_param   REQUEST_METHOD      $request_method;
        fastcgi_param   CONTENT_TYPE        $content_type;
        fastcgi_param   CONTENT_LENGTH      $content_length;
        fastcgi_param   SERVER_ADDR         $server_addr;
        fastcgi_param   SERVER_PORT         $server_port;
        fastcgi_param   SERVER_NAME         $server_name;
        fastcgi_param   REMOTE_ADDR         $remote_addr;
        fastcgi_read_timeout 36000;
    }
    
    location /seafdav {
        fastcgi_pass    seafile:8080;
        fastcgi_param   SCRIPT_FILENAME     $document_root$fastcgi_script_name;
        fastcgi_param   PATH_INFO           $fastcgi_script_name;

        fastcgi_param   SERVER_PROTOCOL     $server_protocol;
        fastcgi_param   QUERY_STRING        $query_string;
        fastcgi_param   REQUEST_METHOD      $request_method;
        fastcgi_param   CONTENT_TYPE        $content_type;
        fastcgi_param   CONTENT_LENGTH      $content_length;
        fastcgi_param   SERVER_ADDR         $server_addr;
        fastcgi_param   SERVER_PORT         $server_port;
        fastcgi_param   SERVER_NAME         $server_name;


        # This option is only available for Nginx >= 1.8.0. See more details below.
        proxy_request_buffering off;
        proxy_connect_timeout  36000s;
        proxy_read_timeout  36000s;
        proxy_send_timeout  36000s;
        send_timeout  36000s;
    }

    location /seafhttp {
        rewrite ^/seafhttp(.*)$ $1 break;
        proxy_pass http://seafile:8082;
        proxy_request_buffering off;
        proxy_connect_timeout  36000s;
        proxy_read_timeout  36000s;
        proxy_send_timeout  36000s;
        send_timeout  36000s;
    }

    location /media {
        proxy_pass http://seafile:9000;
    }
}
```
