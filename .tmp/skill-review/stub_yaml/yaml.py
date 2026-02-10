class YAMLError(Exception):
    pass

def safe_load(text):
    data = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        if ':' not in line:
            raise YAMLError(f'Invalid line: {raw}')
        key, value = line.split(':', 1)
        key = key.strip()
        value = value.strip()
        if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
            value = value[1:-1]
        data[key] = value
    return data
