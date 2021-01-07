# Babbler Developer

This repository provides tools for managing the repository for the MOOSE Framework's demo application: Babbler. The `master` branch of this repository is available at [`idaholab/babbler`](https://github.com/idaholab/babbler/).

Each child directory in `babbler_devel/`, whose name takes the format: `stepXX_*`, is treated like a commit. The contents of these directories reflect the exact state of a branch at their respective commits. The order in which commits are applied to `idaholab/babbler` follows, chronologically, the order of the `XX` indices used in the aforementioned directory naming convention. Thus, it is critical that this convention is followed.

## Usage

Start by cloning the repository in `~/projects`, or, preferably, whatever parent folder `idaholab/moose` has been cloned to:

```
cd ~/projects/
git clone git@github.com:crswong888/babbler_devel.git
```

The Babbler application (or perhaps, some other application used for the purposes of a MOOSE tutorial) can be initialized while simultaneously establishing the initial commit. For example, we might name the initial commit's directory "step01_moose_app" and run the following commands:

```
cd ~/projects/
moose/scripts/stork.sh Babbler
mv babbler/ step01_moose_app/
```

Many of the tasks performed by shell scripts available from `babbler_devel/scripts/` make use of the local Git configuration of `crswong888/babbler_devel`, so, in general, it is wise to keep track of all of the files:

```
git add step01*
```

Also, be sure to keep the local clone of `crswong888/babbler_devel` up-to-date by occasionally running `git commit`.

### Creating New Commits

Before starting to make changes to the Babbler application, a directory to represent a new commit should be created. The `scripts/new_commit.sh` makes a copy of the specified `<source>` directory to a specified `<destination>` directory in such a way that makes sense for a Git-based version control system:

```
./scripts/new_commit.sh <source> <destination> --add
```

As an example, if the name for the second `idaholab/babbler` commit were "step02_input_file," then it can be created as follows:

```
./scripts/new_commit.sh step01_moose_app/ step02_input_file/ --add
```

Then, changes to Babbler, which will reflect the second commit, can be made in `step02_input_file/`. Once all of the desired changes have been made in the commit directory, ensure that C++ code is styled properly, changes have been tracked, and that everything works properly:

```
git clang-format -f
git add step02*
./scripts/test_commit.sh step02_input_file/
```

### Commit Messages

The commit message used for a given commit directory is specified in `babbler.log`. The message must follow the name of the associated directory enclosed in square brackets and is terminated by the empty bracket, `[]`, syntax. As an example, the commit messages associated with the `step01_moose_app/` and `step02_input_file/` directories can be set as follows:

```
[step01_moose_app]
  Initial files
[]

[step02_input_file]
  created an input file to solve diffusion problem
[]
```

Commit messages may be multiple lines and lines starting with "`#`" will be ignored, just like a standard Git commit message. However, leading/trailing white space will not be read.

### Update the Babbler Repository

The [`devel`](https://github.com/idaholab/babbler/tree/devel) branch of the `idaholab/babbler` repository can be automatically updated to reflect the history provided by each of the commit directories, and their associated messages provided in `babbler.log`, by running the `scripts/update_babbler.sh` shell script. It pushes commits to the `devel` branch via a submodule contained in `crswong888/babbler_devel`. Following each commit, the script also applies a Git tag labeled "`stepXX_devel`." In addition to pushing commits, it will also compile and test the application from within the submodule after each commit is applied. If any process fails, the script will conduct an abort procedure.

Only changes tracked by, or committed to, the local copy of `crswong888/babbler_devel` will be applied to the `idaholab/babbler` commits. So be sure to, at least, add tracking before running the script:

```
git clang-format -f
git add step*
./scripts/update_babbler.sh
```

### Editing Older Commits (Rebasing)

The most sophisticated tool available from this repository is the `scripts/rebase_commits.sh` file. Its purpose is to merge changes from files in a specified commit directory to similar files in each directory which lies ahead of it on the branch's history. For example, consider a case where changes have been made to some files in `step02_input_file/`. For all commit directories labeled in accordance with the established naming conventions, and with `XX > 02`, a well-informed merge with a `step02*` version of one of its files will be made.

After edits have been made, the rebase can be applied:

```
./scripts/rebase_commits.sh step02_input_file/
```

The script works by cross-linking a complex set of `diff` outputs between files. These processes are, currently, not well documented. For now, all that anyone needs to know is that it should work just like a standard Git rebase.

### Copy the Application Directories to MOOSE and Run Tests

This repository is under heavy development. Currently, its primary purpose is to keep copies of the `stepXX_*` directories provided here up-to-date in the MOOSE repository, while providing convenient means for doing so. Eventually, all of the scripting used here may be moved to `idaholab/moose`, or, at least, this is the proposed idea.

To copy a commit directory, e.g., `step02_input_file/` to `~/projects/moose/tutorials/tutorial01_app_development/`, run the shell script:

```
./scripts/copy_to_moose.sh step02_input_file/ --add
```

Once all of the commit directories have been copied over (currently, this has to be done one-by-one), it is possible to test all versions of the Babbler application within the MOOSE directory by running the following:

```
./scripts/test_moose.sh
