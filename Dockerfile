FROM debian:buster as builder

# Development tools     
RUN apt-get update && apt-get install -y build-essential autoconf gettext curl

# Download the source file
ENV SYMPA_VERSION 6.2.52
ENV SYMPA_BINARY ${SYMPA_VERSION}.tar.gz

RUN curl -LJO https://github.com/sympa-community/sympa/archive/${SYMPA_BINARY} \
    && tar xzf sympa-${SYMPA_BINARY} -C /usr/src/ \
    && rm sympa-${SYMPA_BINARY}

RUN groupadd sympa \
    && useradd -g sympa -c 'Sympa' -s /sbin/nologin sympa
    
WORKDIR /usr/src/sympa-${SYMPA_VERSION}

# Build and Install Sympa
RUN autoreconf -i

RUN ./configure && make && make install && make clean

# Install Perl modules
RUN apt-get install -y cpanminus
RUN cpanm -L /home/sympa --notest --configure-args='PREFIX=/home/sympa LIB=/home/sympa/lib/perl5' MHonArc::UTF8
RUN cpanm -L /home/sympa/ --installdeps --notest .

# Add directory for mail aliases
RUN mkdir /etc/mail && touch /etc/mail/sympa_aliases && chown sympa:sympa /etc/mail/sympa_aliases
        
# Copy helper scripts for creating Sympa configuration and startup
COPY start-sympa write-sympa-conf sympa.conf.tt2 /home/sympa/

RUN chown -R sympa:sympa /home/sympa

FROM debian:buster

# Replace base Perl and add database drivers
RUN apt-get update && apt-get install -y perl libdbd-pg-perl libdbd-mysql-perl procps

# File /usr/sbin/sendmail does not exist or is not executable
RUN DEBIAN_FRONTEND=noninteractive apt-get install nullmailer

# create sympa user
RUN adduser --disabled-password --gecos '' sympa
        
RUN mkdir /etc/sympa /etc/mail
COPY --from=builder /etc/sympa/ /etc/sympa
COPY --from=builder /etc/mail/ /etc/mail     
COPY --from=builder /home/sympa/ /home/sympa/
WORKDIR /home/sympa

USER sympa

CMD ["/home/sympa/start-sympa"]
