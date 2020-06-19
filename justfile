# use with https://github.com/casey/just


# generate dockerfiles
generate:
	#!/bin/bash

	# Generates base images docker contexts.
	# Recursively copies (merges) files from ./common and
	# curls the newest version of the "official" requirements.txt

	set -Eeuo pipefail

	commonfolder="_spec-common"
	devopssuffix="-devops-additions"


	for path in $(find . -maxdepth 1 -type d -name '_spec-v-*' | grep 'v-....$\|v-master$' | sort) ; do
		name=$(basename "${path}")
		version=${name#"_spec-v-"}
		target="docker/${version}"
		shopt -s extglob
		echo -e "Regenerating output files for verion ${version}..."
		rm -rf "${target}"
		mkdir -p "${target}/prod"
		mkdir -p "${target}/devops"

		echo -e "    Generating dockerfiles for production variant..."
		cp -rp ${commonfolder}/*          "${target}/prod"
		cp -rp "${path}"/*                "${target}/prod"

		for tmpl in $(find "${target}/prod" -name "Dockerfile.*.tmpl" -xtype f | sort | xargs realpath --no-symlinks); do
			cat ${tmpl} >> "${target}/prod/Dockerfile"
			rm -f "${tmpl}"
		done


		echo -e "    Generating dockerfiles with devops additions..."
		cp -rp ${commonfolder}/*                         "${target}/devops"
		[ -d "${commonfolder}${devopssuffix}" ] && \
		  cp -rp ${commonfolder}${devopssuffix}/*        "${target}/devops"
		cp -rp "${path}"/*                               "${target}/devops"
		[ -d "${path}${devopssuffix}" ] && \
		  cp -rp "${path}${devopssuffix}"/*              "${target}/devops"

		for tmpl in $(find "${target}/devops" -name "Dockerfile.*.tmpl" -xtype f | sort | xargs realpath --no-symlinks); do
			cat ${tmpl} >> "${target}/devops/Dockerfile"
			rm -f "${tmpl}"
		done

		echo -e "\033[00;32mFiles for verion ${version} generated.\033[0m\n"
	done

# generate dockerfiles, then build images
build IMAGE="odooops/dockery-odoo": generate
	#!/bin/bash

	# Generates base images per version.
	# Walkes folders matching 'v*' and builds their respective docker context.

	set -Eeuo pipefail

	for path in $(find "$(pwd)" -maxdepth 1 -type d -name 'v-*') ; do
		name=$(basename "${path}")
		version=${name#"v-"}
		docker build --tag "{{ IMAGE }}:${version}" "${name}/out"
	done


# generate dockeriles, build, then push images
push IMAGE="odooops/dockery-odoo": build
	#!/bin/bash

	# Pushes base images per version.
	# Walkes folders matching 'v*' and pushes the respective verion.

	set -Eeuo pipefail

	for path in $(find "$(pwd)" -maxdepth 1 -type d -name 'v-*') ; do
		name=$(basename "${path}")
		version=${name#"v-"}
		docker push "{{ IMAGE }}:${version}"
	done
