# This image provides a Python 3.6 environment you can use to run your Python
# applications.
FROM registry.access.redhat.com/ubi9/s2i-base@sha256:c7544ce1508d8b0bc41c326624257df5f9825175e65528470c27c36f9b48752d

EXPOSE 8080

ENV PYTHON_VERSION=3.12 \
    PATH=$HOME/.local/bin/:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=off

ENV SUMMARY="Platform for building and running Python $PYTHON_VERSION applications" \
    DESCRIPTION="Python $PYTHON_VERSION available as container is a base platform for \
    building and running various Python $PYTHON_VERSION applications and frameworks. \
    Python is an easy to learn, powerful programming language. It has efficient high-level \
    data structures and a simple but effective approach to object-oriented programming. \
    Python's elegant syntax and dynamic typing, together with its interpreted nature, \
    make it an ideal language for scripting and rapid application development in many areas \
    on most platforms."

LABEL summary="$SUMMARY" \
    description="$DESCRIPTION" \
    io.k8s.description="$DESCRIPTION" \
    io.k8s.display-name="Python 3.12" \
    io.openshift.expose-services="8080:http" \
    io.openshift.tags="builder,python,python312,rh-python312,s2i" \
    com.redhat.component="python312-container" \
    name="jefwillems/py312-ubi9-unixodbc" \
    version="1" \
    usage="s2i build . jefwillems/py312-ubi9-unixodbc python-sample-app" \
    maintainer="Jef Willems <willems.jef@outlook.com>"
#! 
#RUN subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
RUN rpm --import http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9
RUN curl https://packages.microsoft.com/config/rhel/9/prod.repo > /etc/yum.repos.d/mssql-release.repo
RUN INSTALL_PKGS="python3.12 python3.12-devel python3.12-setuptools nss_wrapper atlas-devel gcc-gfortran libffi-devel libtool-ltdl msodbcsql17 mssql-tools enchant unixODBC-devel" && \
    ACCEPT_EULA=Y yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*'
RUN yum remove -y nodejs less

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH.
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy extra files to the image.
COPY ./root/ /

# - Create a Python virtual environment for use by any application to avoid
#   potential conflicts with Python packages preinstalled in the main Python
#   installation.
# - In order to drop the root user, we have to make some directories world
#   writable as OpenShift default security model is to run the container
#   under random UID.
# RUN source scl_source enable python3.12 && \
#     virtualenv ${APP_ROOT} && \
#     chown -R 1001:0 ${APP_ROOT} && \
RUN fix-permissions ${APP_ROOT} -P && \
    rpm-file-permissions

# Ensure that odbc is configured to work with freetds
#COPY freetds /tmp/freetds
#COPY odbc_mssql /tmp/odbc_mssql

#RUN cat /tmp/freetds >> /etc/odbcinst.ini && rm /tmp/freetds
#RUN cat /tmp/odbc_mssql >> /etc/odbcinst.ini && rm /tmp/odbc_mssql

USER 1001

# Set the default CMD to print the usage of the language image.
CMD $STI_SCRIPTS_PATH/usage
