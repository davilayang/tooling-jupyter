ARG PYTHON_VERSION
FROM python:${PYTHON_VERSION}-slim-buster

WORKDIR /app

COPY --from=node:14.20.0-buster-slim /usr/local/bin/node /usr/bin/node

RUN apt-get update \
    && apt-get install -y curl vim g++ \
    && rm -rf /var/lib/apt/lists/*

# user fomr --build-args
ARG USER_NAME
RUN useradd --create-home --shell /bin/bash --uid 1000 ${USER_NAME}

USER ${USER_NAME}

ENV PATH="/home/${USER_NAME}/.local/bin:${PATH}"

# install must-have dependencies
RUN pip install --user --no-cache-dir --upgrade \
    "jupyterlab>=3.3.3,<4.0.0" \
    "jupyterlab-vim>=0.15.1,<1.0.0"

# install additional dependencies
COPY requirements.txt requirements.txt 
RUN pip install --user --no-cache-dir --requirement "requirements.txt"

# define color theme for dakr mode, currently support: dracula or monokai
ARG COLOR_THEME=dracula 

# configure jupyter themes
COPY ./theme-dark-extension/index-${COLOR_THEME}.css \
    /home/${USER_NAME}/.local/share/jupyter/lab/themes/@jupyterlab/theme-dark-extension/index.css
COPY ./theme-light-extension/index.css \
    /home/${USER_NAME}/.local/share/jupyter/lab/themes/@jupyterlab/theme-light-extension/index.css

# configure bash prompt
RUN echo "PS1='\[\e[0;37m\][\w]\\\n\[\e[1;35m\]\u\[\e[1;34m\]@🐳\[\e[1;36m\]\h\[\e[1;34m\] ❯ \[\e[0m\]'" \
    >> /home/${USER_NAME}/.bashrc

# finalizations
EXPOSE 8888

ENTRYPOINT ["jupyter", "lab"]
CMD ["--ip=0.0.0.0", "--port=8888", "--no-browser", "--ServerApp.token="]

# TODO: use multi-stage builds
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
# FIXME: why need g++, that wasnt needed before
