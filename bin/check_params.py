#!/usr/bin/env python
import sys
from drevalpy.utils import get_parser, check_arguments


def main(argv=None):
    """Coordinate argument parsing and program execution."""
    args = get_parser().parse_args(argv)
    check_arguments(args)


if __name__ == "__main__":
    sys.exit(main())
