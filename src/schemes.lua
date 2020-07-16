local schema = {
    user = {
        type="record",
        name="user_schema",
        fields={
            {name="id", type="long"},
            {name="username", type="string"},
            {name="phone", type="string"},
            {name="is_super", type="boolean"},
        }
    },
    price = {
        type="record",
        name="price_schema",
        fields={
            {name="id", type="long"},
            {name="price_value", type="float"},
            {name="date_created", type="string"},
            {name="approved", type="boolean"},
            {name="product",
             type={
                type="record",
                name="price_product",
                fields={
                    {name="UUID", type="string"},
                    {name="name", type="string"}
                }
            }
        }
        }
    }
}

return schema