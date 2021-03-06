from sys import argv
from convert_world import convert_world
from mapdata import mapdata, COMMAND_SAVE, LEVEL_COUNT


def main():
    start = int(argv[1])
    try:
        stop = int(argv[2])
    except IndexError:
        stop = LEVEL_COUNT

    if not (1 <= start < stop <= LEVEL_COUNT):
        raise ValueError(F'Range must be between 1 and {LEVEL_COUNT}')

    try:
        for i in range(start, stop+1):
            print('Screen', i)
            convert_world(i)
            # reload()
            input('Press enter to save and continue\n')
            mapdata(COMMAND_SAVE, i)
            print('\n')
    except KeyboardInterrupt:
        print('\n^C')
        print(i)


if __name__ == '__main__':
    main()
