from time import sleep


def application(environ, start_response):
    sleep_str = environ['PATH_INFO'].strip('/')
    if sleep_str:
        try:
            sleep_float = float(sleep_str)
        except ValueError:
            raise ValueError('Path must be an integer or float.')
        sleep(sleep_float)
    status = '200 OK'
    headers = [('Content-type', 'text/plain')]
    start_response(status, headers)
    return [b"Hello Gunicorn!\n"]
