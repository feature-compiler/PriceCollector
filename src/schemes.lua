local schema = {
    user = {
        type="record",
        name="user_schema",
        fields={
            {name="id", type="long"},
            {name="username", type="string"},
            {name="phone", type="string"},
            {name="is_super", type="boolean"},
            {name="salt", type="string"},
            {name="shadow", type="string"},
        }
    },
    price = {
        type="record",
        name="price_schema",
        fields={
            {name="id", type="long"},
            {name="price", type="float"},
            {name="datetime", type="string"},
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
            {name="jwt", type="string"},
        }
    },
    product = {
        type="record",
        name="product_schema",
        fields={
            {name="id", type="long"},
            {name="name", type="string"},
            {name="uuid", type="string"},     
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
            {name="product_id", type="long"},
            {name="barcode", type="string"},
        }
    }
}

return schema