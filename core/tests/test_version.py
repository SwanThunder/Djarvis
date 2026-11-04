from importlib.metadata import version

from packaging.version import Version

import djarvis_core

DISTRIBUTION_NAME = "djarvis-core"


def test_version_matches_installed_metadata() -> None:
    assert djarvis_core.__version__ == version(DISTRIBUTION_NAME)


def test_version_is_normalized_pep440() -> None:
    parsed = Version(djarvis_core.__version__)

    assert str(parsed) == djarvis_core.__version__
