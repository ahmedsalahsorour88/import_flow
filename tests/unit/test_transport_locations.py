import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.transport_locations.model import TransportLocation
from modules.transport_locations.schemas import TransportLocationCreate, TransportLocationUpdate
from modules.transport_locations.service import TransportLocationService
from fastapi import HTTPException


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


class TestTransportLocationsBackend:

    def test_create_transport_location(self, db_session):
        service = TransportLocationService(db_session)
        data = TransportLocationCreate(
            un_locode="egaly",
            location_name="Alexandria Port",
            location_type="Sea Port",
            country="Egypt",
            city="Alexandria",
            notes="Main Port",
        )
        loc = service.create(data)

        assert loc.location_id is not None
        assert loc.un_locode == "EGALY"  # Uppercased automatically
        assert loc.location_name == "Alexandria Port"
        assert loc.is_active is True

    def test_duplicate_un_locode_raises_400(self, db_session):
        service = TransportLocationService(db_session)
        data = TransportLocationCreate(
            un_locode="EGCAI",
            location_name="Cairo Airport",
            location_type="Airport",
            country="Egypt",
            city="Cairo",
        )
        service.create(data)

        with pytest.raises(HTTPException) as exc_info:
            service.create(data)

        assert exc_info.value.status_code == 400
        assert "already exists" in exc_info.value.detail

    def test_get_all_filtering_and_search(self, db_session):
        service = TransportLocationService(db_session)
        service.create(TransportLocationCreate(un_locode="EGALY", location_name="Alexandria Port", location_type="Sea Port", country="Egypt", city="Alexandria"))
        service.create(TransportLocationCreate(un_locode="EGCAI", location_name="Cairo Airport", location_type="Airport", country="Egypt", city="Cairo"))
        service.create(TransportLocationCreate(un_locode="CNSHA", location_name="Shanghai Port", location_type="Sea Port", country="China", city="Shanghai"))

        sea_ports = service.get_all(location_type="Sea Port")
        assert len(sea_ports) == 2

        china_locs = service.get_all(country="China")
        assert len(china_locs) == 1
        assert china_locs[0].un_locode == "CNSHA"

        search_results = service.get_all(search="Cairo")
        assert len(search_results) == 1
        assert search_results[0].un_locode == "EGCAI"

    def test_update_transport_location(self, db_session):
        service = TransportLocationService(db_session)
        loc = service.create(TransportLocationCreate(un_locode="EGSOK", location_name="Sokhna Port", location_type="Sea Port", country="Egypt", city="Suez"))

        updated = service.update(loc.location_id, TransportLocationUpdate(location_name="Ain Sokhna Deepwater Port"))
        assert updated.location_name == "Ain Sokhna Deepwater Port"

    def test_soft_delete_and_restore(self, db_session):
        service = TransportLocationService(db_session)
        loc = service.create(TransportLocationCreate(un_locode="EGSLM", location_name="Salloum Port", location_type="Land Border", country="Egypt", city="Matrouh"))

        # Soft delete
        service.soft_delete(loc.location_id)
        active_list = service.get_all(include_inactive=False)
        assert len(active_list) == 0

        # Restore
        restored = service.restore(loc.location_id)
        assert restored.is_active is True
        active_list = service.get_all(include_inactive=False)
        assert len(active_list) == 1
