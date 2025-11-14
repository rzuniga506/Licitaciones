"""
Database initialization script.
Creates initial admin user and sample data.
"""
from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.db.session import SessionLocal
from app.models.user import User


def init_db(db: Session) -> None:
    """
    Initialize database with default data.

    Creates:
    - Default admin user
    """
    # Check if admin user exists
    admin = db.query(User).filter(User.username == "admin").first()

    if not admin:
        print("Creating default admin user...")
        admin = User(
            email="admin@licitaciones.com",
            username="admin",
            hashed_password=get_password_hash("admin123"),  # Change this in production!
            full_name="System Administrator",
            role="admin",
            is_active=True
        )
        db.add(admin)
        db.commit()
        db.refresh(admin)
        print(f"✅ Admin user created: {admin.username}")
        print("⚠️  IMPORTANT: Change the default password immediately!")
    else:
        print("ℹ️  Admin user already exists.")


def create_sample_users(db: Session) -> None:
    """Create sample users for testing."""
    sample_users = [
        {
            "email": "coordinator@licitaciones.com",
            "username": "coordinator",
            "password": "coordinator123",
            "full_name": "John Coordinator",
            "role": "coordinator"
        },
        {
            "email": "analyst@licitaciones.com",
            "username": "analyst",
            "password": "analyst123",
            "full_name": "Jane Analyst",
            "role": "analyst"
        },
        {
            "email": "viewer@licitaciones.com",
            "username": "viewer",
            "password": "viewer123",
            "full_name": "Bob Viewer",
            "role": "viewer"
        }
    ]

    for user_data in sample_users:
        existing = db.query(User).filter(User.username == user_data["username"]).first()
        if not existing:
            user = User(
                email=user_data["email"],
                username=user_data["username"],
                hashed_password=get_password_hash(user_data["password"]),
                full_name=user_data["full_name"],
                role=user_data["role"],
                is_active=True
            )
            db.add(user)
            print(f"✅ Sample user created: {user.username}")

    db.commit()
    print("✅ Sample users created successfully!")


if __name__ == "__main__":
    print("Initializing database...")
    db = SessionLocal()
    try:
        init_db(db)
        # Uncomment to create sample users
        # create_sample_users(db)
        print("✅ Database initialization completed!")
    except Exception as e:
        print(f"❌ Error initializing database: {e}")
    finally:
        db.close()
