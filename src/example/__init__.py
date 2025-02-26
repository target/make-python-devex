from typing import List
import atexit

from loguru import logger


def main() -> None:
    logger.info("Starting")

    do_something()

    atexit.register(lambda: logger.info("Exiting!"))


def do_something() -> None:
    inputs = [1, 2]
    logger.debug(f"Doing something with {inputs}")
    output = sum_numbers(inputs)
    logger.info(f"Got {output}")


def sum_numbers(nums: List[int]) -> int:
    return sum(nums)
