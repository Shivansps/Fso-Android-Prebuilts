Optional patches applied to the FSO source tree.

build_fso_android.sh applies every *.patch in this folder, in sorted filename
order, right after:
    git clone https://github.com/Shivansps/fs2open.github.com --recursive
    cd fs2open.github.com && git checkout android-build

Rules:
  * Files must end in .patch and be git-style diffs (git apply is used).
  * Order is alphabetical, so prefix with numbers: 0001-..., 0002-..., etc.
  * If there are no .patch files, the build proceeds normally (no-op).
  * If a patch fails to apply, an option to continue or abort is given

How to create one (from inside a checked-out fs2open.github.com on android-build):
    # make your changes, then:
    git diff > /path/to/repo/patchs/0001-my-change.patch
    # or for a committed change:
    git format-patch -1 -o /path/to/repo/patchs
