from sqlalchemy.orm import Query


# ==================================================
# Active Filter
# ==================================================

def active_only(
    query: Query,
    model
) -> Query:

    return query.filter(
        model.is_active == True
    )


# ==================================================
# Search By Name
# ==================================================

def search_by_name(
    query: Query,
    column,
    keyword: str | None
) -> Query:

    if keyword:

        query = query.filter(
            column.ilike(
                f"%{keyword}%"
            )
        )

    return query


# ==================================================
# Order By ID
# ==================================================

def order_by_id(
    query: Query,
    column
) -> Query:

    return query.order_by(column)