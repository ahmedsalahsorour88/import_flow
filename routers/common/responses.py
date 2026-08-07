from typing import Any

from fastapi.responses import JSONResponse
from fastapi import status


# ==================================================
# Success Response
# ==================================================

def success_response(
    message: str,
    data: Any = None,
    status_code: int = status.HTTP_200_OK
) -> JSONResponse:

    return JSONResponse(
        status_code=status_code,
        content={
            "success": True,
            "message": message,
            "data": data
        }
    )


# ==================================================
# Error Response
# ==================================================

def error_response(
    message: str,
    status_code: int = status.HTTP_400_BAD_REQUEST
) -> JSONResponse:

    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "message": message
        }
    )


# ==================================================
# Created Response
# ==================================================

def created_response(
    message: str,
    data: Any = None
) -> JSONResponse:

    return success_response(
        message=message,
        data=data,
        status_code=status.HTTP_201_CREATED
    )


# ==================================================
# No Content Response
# ==================================================

def no_content_response() -> JSONResponse:

    return JSONResponse(
        status_code=status.HTTP_204_NO_CONTENT,
        content=None
    )