select
  {{ dbt_utils.star(from=ref('some_other_model'), quote_identifiers=False) }}
from {{ ref('some_other_model') }}
