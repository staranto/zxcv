FROM ubuntu:20.04

RUN  apt update && \
     apt install -y curl fzf git

RUN  git clone https://github.com/asdf-vm/asdf.git ${HOME}/.asdf --branch v0.10.0 
RUN  bash -c ". ${HOME}/.asdf/asdf.sh"
RUN  ls -lta ${HOME}/.asdf && ls -lta ${HOME}
RUN  asdf update && asdf plugin add terraform

RUN  mkdir -p ${HOME}/dev && \
     cd ${HOME}/dev && \
     git clone https://github.com/staranto/zxcv.git && \
     cd ${HOME}/dev/zxcv && \
     git checkout develop

RUN  mkdir ${HOME}/.config
COPY <<EOF
hostname=app.terraform.io
organization=staranto
EOF

COPY <<EOF
{
  "credentials": {
    "app.terraform.io": {
      "token": "yQlSTuG7eHtp2g.atlasv1.lhEXASnbwJNA2UKiFvhOqEsEFU4xIUXjKIcyUfnduQ60PiaEBZ3CW9BfV7onoEZAg0w"
    }
  },
  "disable_checkpoint": true
}
EOF

RUN cat<<EOF >> ${HOME}/.bashrc
export REPO_BASEDIR=${HOME}/dev
export ZXCV_BASEDIR=${HOME}/dev/zxcv
for f in ${ZXCV_BASEDIR}/misc; do [[ -f "${f}" ]] && . "${f}"; done
sall ${ZXCV_BASEDIR}/zxcv
EOF
