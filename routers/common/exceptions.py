from fastapi import HTTPException
from fastapi import status


# ==================================================
# 400 Bad Request
# ==================================================

class BadRequestException(HTTPException):

    def __init__(
        self,
        detail: str = "Bad Request"
    ):

        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=detail
        )


# ==================================================
# 404 Not Found
# ==================================================

class NotFoundException(HTTPException):

    def __init__(
        self,
        detail: str = "Resource not found"
    ):

        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=detail
        )


# ==================================================
# 409 Conflict
# ==================================================

class ConflictException(HTTPException):

    def __init__(
        self,
        detail: str = "Resource already exists"
    ):

        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=detail
        )


# ==================================================
# 401 Unauthorized
# ==================================================

class UnauthorizedException(HTTPException):

    def __init__(
        self,
        detail: str = "Unauthorized"
    ):

        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail
        )


# ==================================================
# 403 Forbidden
# ==================================================

class ForbiddenException(HTTPException):

    def __init__(
        self,
        detail: str = "Forbidden"
    ):

        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail
        )


# ==================================================
# 422 Validation Error
# ==================================================

class ValidationException(HTTPException):

    def __init__(
        self,
        detail: str = "Validation Error"
    ):

        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=detail
        )


# ==================================================
# 500 Internal Server Error
# ==================================================

class InternalServerException(HTTPException):

    def __init__(
        self,
        detail: str = "Internal Server Error"
    ):

        super().__init__(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=detail
        )