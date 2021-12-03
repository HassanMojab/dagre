# Fail on error
set -e
[ -n "$DEBUG"] && set -x

bail() {
    echo $1 >&2
    exit 1
}

# Initial config
PROJECT=$1
PROJECT_ROOT=`pwd`
PAGES_DIR=/tmp/$PROJECT-pages
DIST_DIR=$2

# Check version. Is this a release? If not abort
VERSION=$(./src/release/check-version.js)
SHORT_VERSION=$(echo $VERSION | cut -f1 -d-)

echo Attemping to publish version: $VERSION

# Preflight checks
[ -n "$PROJECT" ] || bail "No project name was specified."
[ -n "$DIST_DIR" ] || bail "No dist dir was specified."
[ -z "`git tag -l v$VERSION`" ] || bail "Version already published. Skipping publish."
[ "`git rev-parse HEAD`" = "`git rev-parse master`" ] || [ -n "$PRE_RELEASE" ] || bail "ERROR: You must release from the master branch"
[ -z "`git status --porcelain`" ] || bail "ERROR: Dirty index on working tree. Use git status to check"

# Publish tag
git tag v$VERSION
git push origin
git push origin v$VERSION
echo Published $PROJECT v$VERSION

# Publish to npm
npm publish --access=public
echo Published to npm

# Update patch level version + commit
./src/release/bump-version.js
make lib/version.js
git commit package.json lib/version.js -m "Bump version and set as pre-release"
git push origin
echo Updated patch version

echo Release complete!
