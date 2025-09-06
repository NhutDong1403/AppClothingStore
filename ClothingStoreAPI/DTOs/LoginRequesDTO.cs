namespace ClothingStoreAPI.DTOs
{
    public class LoginRequestDTO
    {
        public string Username { get; set; } = null!;
        public string Password { get; set; } = null!;
    }

    public class LoginResponseDTO
    {
       
        public string Username { get; set; } = null!;
        public string Role { get; set; } = null!;
    }
}
