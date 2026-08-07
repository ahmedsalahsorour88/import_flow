from fastapi import Query


# ==================================================
# Pagination
# ==================================================

def pagination_params(

    page: int = Query(
        1,
        ge=1
    ),

    page_size: int = Query(
        20,
        ge=1,
        le=100
    )

):

    skip = (page - 1) * page_size

    return {
        "page": page,
        "page_size": page_size,
        "skip": skip,
        "limit": page_size
    }