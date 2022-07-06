package blog

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
)

dagger.#Plan & {
	client: {
		filesystem: {
			// TODO: Can be replaced once I port my deploy logic to Dagger too.
			// Then the output from the build action is just input to the deploy action.
			"./_site": write: contents: actions.build.output
		}
	}
	actions: {
		source: core.#Source & {
			path: "."
			exclude: [
				"_site",
				"*.cue",
				"*.md",
				".git",
				"examples",
				".github",
			]
		}

		build: {
			#Exec & {
				args: ["jekyll", "build", "--source", "blog.mads-hartmann.com", "--destination", "/_site"]
				outputDir: "/_site"
				source:    actions.source.output
			}
		}

		watch: {
			#Exec & {
				args: ["jekyll", "serve", "--source", "blog.mads-hartmann.com", "--watch", "--draft"]
				source: actions.source.output
			}
		}
	}
}
