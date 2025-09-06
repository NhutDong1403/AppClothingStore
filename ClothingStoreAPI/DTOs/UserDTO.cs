namespace ClothingStoreAPI.DTOs
{
    public class UserDTO
    {
        public int Id { get; set; }
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Role { get; set; } = Roles.User;

        public static class Roles
        {
            public const string Admin = "Admin";
            public const string User = "User";
            // Thêm role khác nếu cần
        }
    }
}
