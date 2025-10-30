FROM ubuntu:25.04

# Set environment variables
ENV USER=ubuntu
ENV HOME=/home/ubuntu
ENV TZ='UTC'

# Set working directory
WORKDIR $HOME

# Insert Steam prompt answers
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
 && echo steam steam/license note '' | debconf-set-selections

# Update the repository and install SteamCMD
ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture i386 \
 && apt-get update -y \
 && apt-get install -y --no-install-recommends ca-certificates locales steamcmd wine wine32 wine64 xvfb xauth wget gosu winbind cabextract libsdl3-dev unzip python3 procps curl \
 && rm -rf /var/lib/apt/lists/*

ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en' 
RUN locale-gen en_US.UTF-8

# Create symlink for executable
RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd

# install winetricks
ARG WINETRICKS_VERSION=20250102
ADD "https://raw.githubusercontent.com/Winetricks/winetricks/refs/tags/$WINETRICKS_VERSION/src/winetricks" /usr/bin/winetricks
RUN chmod 0755 /usr/bin/winetricks

# Initialize Wine prefix and install dependencies
RUN su -s /bin/bash -c "xvfb-run -a winetricks --unattended vcrun2022 corefonts" - ubuntu

# Import system certificates into Wine's certificate store
RUN update-ca-certificates
# RUN su -s /bin/bash -c "wine reg add 'HKLM\\Software\\Microsoft\\SystemCertificates\\Root\\Certificates' /f" - ubuntu

# Update SteamCMD and verify latest version
RUN su -s /bin/bash -c "steamcmd +quit" - ubuntu 

# Fix missing directories and libraries
RUN mkdir -p $HOME/.steam \
 && ln -s $HOME/.local/share/Steam/steamcmd/linux32 $HOME/.steam/sdk32 \
 && ln -s $HOME/.local/share/Steam/steamcmd/linux64 $HOME/.steam/sdk64 \
 && ln -s $HOME/.steam/sdk32/steamclient.so $HOME/.steam/sdk32/steamservice.so \
 && ln -s $HOME/.steam/sdk64/steamclient.so $HOME/.steam/sdk64/steamservice.so

# Copy batch files and give execute rights
ADD ./files $HOME/scripts
RUN chmod +x $HOME/scripts/*.sh && chmod +x $HOME/scripts/healthcheck.py
RUN mkdir -p /home/ubuntu/server_files && chown -R ubuntu:ubuntu /home/ubuntu/server_files

# Expose health check port
EXPOSE 8080

# Add Docker healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run start as steam user 
ENTRYPOINT ["/home/ubuntu/scripts/entrypoint.sh"]

CMD ["/bin/bash", "/home/ubuntu/scripts/start.sh"]
