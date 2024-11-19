select
    origin_system,
    data_system
from (
    values
    ('vmx', 'csv'),
    ('local', 'excel')
    as v(origin_system, data_system)
)
