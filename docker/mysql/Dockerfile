FROM mariadb:10.6

# Install jq only once during build
# RUN microdnf update -y && \
#     microdnf --noplugins install -y jq \
#     --setopt=install_weak_deps=0 \
#     --setopt=tsflags=nodocs && \
#     microdnf clean all

# Install jq only once during build for config json file parsing
# Install jq in a single RUN command
# Ensure init.sh is executable


RUN apt-get clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends jq && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /docker-entrypoint-initdb.d

# Copy init scripts into the container
COPY init.sh /init.sh
COPY init.sql /init.sql

RUN chmod +x /init.sh


# Use the original MySQL entrypoint and run init.sh after MySQL starts
# CMD ["bash", "-c", "docker-entrypoint.sh mysqld && /init.sh"]
# CMD ["bash", "-c", "chown mysql:mysql /init.sh && chmod +x /init.sh &&  & sleep 10 && su mysql -c /init.sh"]
CMD ["bash", "-c", "cp /init.sh /tmp/init.sh && chmod +x /tmp/init.sh && chown mysql:mysql /tmp/init.sh && docker-entrypoint.sh mysqld && sleep 5 && bash /tmp/init.sh "]


