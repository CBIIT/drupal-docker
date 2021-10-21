Run as follows:

docker run --name alpine -p 8081:80 -e sitename=webteam -e dbhost=192.168.0.178 -e dbport=3306 -e dbuser=root -e dbpass=password -e dbname=webteam -e user=admin -e pass=1234 alpine
