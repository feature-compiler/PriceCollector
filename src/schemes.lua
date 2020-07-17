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
            {name="product_id", type="long"},
            {name="shop_id", type="long"},
        }
    },
    token = {
        type="record",
        name="token_schema",
        fields={
            {name="user_id", type="long"},
            {name="salt", type="string"},
            {name="shadow", type="string"}
        }
    },
    product = {
        type="record",
        name="product_schema",
        fields={
            {name="id", type="long"},
            {name="uuid", type="string"},
            {name="name", type="string"},
        }
    },
    shop = {
        type="record",
        name="shop_schema",
        fields={
            {name="id", type="long"},
            {name="uuid", type="string"},
            {name="name", type="string"},
        }

    },
    barcode = {
        type="record",
        name="barcode_schema",
        fields={
            {name="barcode", type="string"},
            {name="product_id", type="long"},
        }
    }
}

return schema