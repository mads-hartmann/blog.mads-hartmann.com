// 
// Definitions used for actions that want to use "bundle"
//
// This is mostly taken from yarn.cue and then modified so it uses Bundler.
// https://github.com/dagger/dagger/blob/main/pkg/universe.dagger.io/yarn/yarn.cue
// 
package blog

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/alpine"
)

// Install dependencies with bundle ('bundle install')
#Install: #Command & {
	args: ["install"]
}

// Run bundle exec ('bundle exec <args>')
#Exec: {

	project: string | *"default"

	// App source code
	source: dagger.#FS

	args: [...string]

	outputDir: string | *"./build"

	output: command.output

	command: #Command & {
		"source":    source
		"project":   project
		"args":      ["exec"] + args
		"outputDir": outputDir

		// Mount output directory of install command,
		//   even though we don't need it,
		//   to trigger an explicit dependency.
		container: mounts: install_output: {
			contents: install.output
			dest:     "/tmp/bundle_install_output"
		}
	}

	install: #Install & {
		"source":  source
		"project": project
	}

}

// Run a bundler command (`bundle <ARGS>')
#Command: {
	// Source code to build
	source: dagger.#FS

	// Arguments to bundle
	args: [...string]

	// Project name, used for cache scoping
	project: string | *"default"

	// Path of the bundle script's output directory
	// May be absolute, or relative to the workdir
	outputDir: string | *"./build"

	// Output directory
	output: container.export.directories."/output"

	// Logs produced by the bundle script
	logs: container.export.files."/logs"

	container: bash.#Run & {
		"args": args

		input:  *_image.output | _
		_image: alpine.#Build & {
			packages: {
				bash: {}
				make: {}
				gcc: {}
				"g++": {}
				"ruby-dev": {}
				"ruby-bundler": {}
				"musl-dev": {}
			}
		}

		workdir: "/src"
		mounts: Source: {
			dest:     "/src"
			contents: source
		}
		script: contents: """
			set -x
			bundle "$@" | tee /logs
			echo $$ > /code
			if [ -e "$BUNDLE_OUTPUT_FOLDER" ]; then
				mv "$BUNDLE_OUTPUT_FOLDER" /output
			else
				mkdir /output
			fi
			"""
		export: {
			directories: "/output": dagger.#FS
			files: {
				"/logs": string
				"/code": string
			}
		}

		// Setup caching
		env: {
			BUNDLE_OUTPUT_FOLDER: outputDir
		}
		mounts: {
			// Ensures that the gems installed by bundler are accessible
			// in any command command execution in the same "project"
			"Bundle cache": {
				dest:     "/src/vendor"
				contents: core.#CacheDir & {
					id: "\(project)-bundle"
				}
			}
		}
	}
}
