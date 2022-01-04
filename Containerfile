FROM registry.access.redhat.com/ubi8

ARG USER=ray
ARG HOME=/home/ray

# If you make changes to this Containerfile, check to see if corresponding changes should be
# made to the ray-operator Containerfile

# I will use tini in the entrypoint to do proper signal handling and process tree hygiene
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /usr/bin/tini
RUN chmod a+rx /usr/bin/tini

ENV USER=${USER} HOME=${HOME}
WORKDIR ${HOME}

# WORKON_HOME tells pipenv to put the virtualenv in same dir so
# it gets properly used when container runs using anonymous uid
ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    LC_CTYPE="C.UTF-8" \
    WORKON_HOME=${HOME} \
    PIPENV_NOSPIN=1 \
    PIPENV_NO_INHERIT=True

RUN echo \
 && echo -e "\ninstalling OS package deps" \
 && dnf install -y --setopt=tsflags=nodocs procps-ng wget tar gzip python38 python38-devel python3-pip gcc gcc-c++ make cmake \
 && dnf clean all \
 && echo -e "\ninstalling pipenv" \
 && pip3 install --upgrade pip \
 && pip3 install pipenv==2020.11.15 \
 && echo

# install ray deps
COPY Pipfile ${HOME}
COPY Pipfile.lock ${HOME}
RUN echo \
 && pipenv install \
 && rm -rf /tmp/* /root/.cache /root/.local \
 && touch ${HOME}/.bashrc \
 && chmod a+rwX -R ${HOME} \
 && echo

# in the above, ray has been installed as a pipenv environment - if you want to run
# ray on this image, a way to do this is:
# $ cd $HOME
# pipenv run ray start ...
# or, alternatively:
# $ cd $HOME
# $ . $(pipenv --venv)/bin/activate
# $ ray start ...

# to build images with additional dependencies installed:
# FROM <this image>
# RUN cd ${HOME} && pipenv install ...

COPY entrypoint.sh /usr/bin
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]

CMD [ "echo", "no default command" ]

# Emulate an anonymous uid
USER 9999:0
