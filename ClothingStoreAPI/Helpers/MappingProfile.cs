using AutoMapper;
using ClothingStoreAPI.DTOs;
using ClothingStoreAPI.Models;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        // Product - Category
        CreateMap<Product, ProductDTO>().ReverseMap();
        CreateMap<Category, CategoryDTO>().ReverseMap();
        CreateMap<CreateCategoryDTO, Category>();

        // User
        CreateMap<User, UserDTO>().ReverseMap();
        CreateMap<CreateUserDTO, User>()
            .ForMember(dest => dest.PasswordHash, opt => opt.Ignore());

        // OrderDetail -> OrderItemDTO (vì Items trong OrderDTO là List<OrderItemDTO>)
        CreateMap<OrderDetail, OrderItemDTO>()
            .ForMember(dest => dest.ProductName, opt => opt.MapFrom(src => src.Product != null ? src.Product.Name : "Không rõ"))
            .ForMember(dest => dest.Price, opt => opt.MapFrom(src => src.UnitPrice));



        // Order -> OrderDTO, ánh xạ OrderDetails -> Items
        CreateMap<Order, OrderDTO>()
            .ForMember(dest => dest.Items, opt => opt.MapFrom(src => src.OrderDetails));

        // Ngược lại (nếu cần dùng khi POST đơn hàng từ client)
        CreateMap<OrderItemDTO, OrderDetail>();
        CreateMap<OrderDTO, Order>();
        CreateMap<Voucher, VoucherDto>().ReverseMap();


        // Khi tạo đơn hàng
        CreateMap<OrderItemDTO, OrderDetail>()
            .ForMember(dest => dest.UnitPrice, opt => opt.MapFrom(src => src.Price));
        CreateMap<CreateOrderDTO, Order>()
            .ForMember(dest => dest.OrderDetails, opt => opt.MapFrom(src => src.Items));
        CreateMap<Order, OrderAdminDto>()
    .ForMember(dest => dest.Items, opt => opt.MapFrom(src => src.OrderDetails));
    }
}
